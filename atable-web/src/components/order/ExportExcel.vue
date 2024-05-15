<template>
  <v-card
    title="Fournisseurs"
    subtitle="Vous pouvez associer à chaque ingrédient un fournisseur."
  >
    <v-card-text>
      <v-row>
        <v-col cols="5">
          <v-select
            clearable
            persistent-hint
            :hint="
              mapping.baseProfile == null
                ? `Aucun fournisseur : les ingrédients sont regroupés par catégorie.`
                : `Fournisseurs: ${formatSuppliers(suppliers)}`
            "
            class="mt-2"
            variant="outlined"
            density="compact"
            label="Choix des fournisseurs"
            :items="
              profiles.map((pr) => ({
                title: pr.Profile.Name,
                value: pr,
              }))
            "
            v-model="mapping.baseProfile"
            @update:model-value="syncProfileContent"
          >
          </v-select>
        </v-col>

        <v-col>
          <v-card
            v-if="mapping.baseProfile != null"
            subtitle="Associations ingrédients / fournisseurs"
          >
            <template v-slot:append>
              <v-chip size="small" color="secondary">
                {{ mapping.customMapping.size }} choix personnalisé{{
                  mapping.customMapping.size > 1 ? "s" : ""
                }}
              </v-chip>
            </template>
            <v-card-text>
              <v-list max-height="55vh" class="overflow-y-auto">
                <v-list-item title="Ingrédient">
                  <template v-slot:append> Fournisseur </template>
                </v-list-item>
                <v-list-item
                  density="compact"
                  rounded
                  v-for="(ingredient, index) in sortedIngredients"
                  :key="index"
                  :title="ingredient.Name"
                  :subtitle="IngredientKindLabels[ingredient.Kind]"
                  :class="
                    'my-1 ' +
                    (mapping.customMapping.has(ingredient.Id)
                      ? 'bg-secondary-lighten'
                      : '')
                  "
                >
                  <template v-slot:append>
                    <v-menu>
                      <template v-slot:activator="{ isActive, props }">
                        <v-chip
                          v-on="{ isActive }"
                          v-bind="props"
                          elevation="2"
                        >
                          {{ supplierFor(ingredient.Id) }}
                        </v-chip>
                      </template>
                      <v-list>
                        <v-list-item
                          v-for="(supplier, index) in suppliers"
                          :key="index"
                          :title="supplier.Name"
                          @click="updateMapping(ingredient.Id, supplier.Id)"
                        ></v-list-item>
                      </v-list>
                    </v-menu>
                  </template>
                </v-list-item>
              </v-list>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>
    </v-card-text>

    <v-card-actions>
      <v-spacer> </v-spacer>
      <v-btn @click="downloadExcel" color="success">Exporter</v-btn>
    </v-card-actions>
  </v-card>
</template>

<script lang="ts" setup>
import {
  type ProfileHeader,
  IngredientKindLabels,
  IdIngredient,
  IdSupplier,
  CompileIngredientsOut,
  Int,
} from "@/logic/api_gen";
import {
  OrderIngredientMapping,
  controller,
  formatSuppliers,
  saveBlobAsFile,
} from "@/logic/controller";
import { computed, reactive, onMounted, ref } from "vue";

const props = defineProps<{
  compiledIngredients: CompileIngredientsOut;
  days: Int[];
}>();

const emit = defineEmits<{
  (e: "done"): void;
}>();

onMounted(async () => {
  await fetchProfiles();
  const defaultProfile = sejour.value?.IdProfile || {
    Valid: false,
  };
  if (defaultProfile.Valid) {
    mapping.baseProfile = profiles.value.find(
      (pr) => pr.Profile.Id == defaultProfile.IdProfile
    )!;
  }
  syncProfileContent();
});

const sejour = computed(() => controller.activeSejour?.Sejour || null);

const sortedIngredients = computed(() => {
  const out =
    props.compiledIngredients.Ingredients?.map((ing) => ing.Ingredient) || [];
  out.sort((a, b) =>
    a.Kind == b.Kind ? a.Name.localeCompare(b.Name) : a.Kind - b.Kind
  );
  return out;
});

const mapping = reactive<OrderIngredientMapping>({
  baseProfile: null,
  customMapping: new Map(),
});

const suppliers = computed(() => {
  return Object.values(mapping.baseProfile?.Suppliers || {});
});

const currentProfileContent = ref(new Map<IdIngredient, IdSupplier>());
async function syncProfileContent() {
  mapping.customMapping.clear();
  currentProfileContent.value.clear();

  const bp = mapping.baseProfile;
  if (bp == null) return;

  const res = await controller.OrderGetDefaultMapping({
    Profile: bp.Profile.Id,
    Ingredients:
      props.compiledIngredients.Ingredients?.map((ing) => ing.Ingredient.Id) ||
      [],
  });
  if (res == undefined) return;

  Object.entries(res).forEach((e) =>
    currentProfileContent.value.set(Number(e[0]) as Int, e[1])
  );
}

function supplierFor(id: IdIngredient) {
  const idSupplierCustom = mapping.customMapping.get(id);
  if (idSupplierCustom != undefined) {
    const supplier = (mapping.baseProfile?.Suppliers || {})[idSupplierCustom];
    return supplier.Name;
  }
  const idSupplierBase = currentProfileContent.value.get(id);
  if (idSupplierBase != undefined) {
    const supplier = (mapping.baseProfile?.Suppliers || {})[idSupplierBase];
    return supplier.Name;
  }
  return "Aucun";
}

function updateMapping(idIngredient: IdIngredient, idSupplier: IdSupplier) {
  // do not show as custom if already in base
  if (currentProfileContent.value.get(idIngredient) == idSupplier) {
    mapping.customMapping.delete(idIngredient);
  } else {
    mapping.customMapping.set(idIngredient, idSupplier);
  }
}

async function downloadExcel() {
  // merge the two mappings
  const merged = Object.fromEntries(currentProfileContent.value.entries());
  for (const item of mapping.customMapping.entries()) {
    merged[item[0]] = item[1];
  }

  const res = await controller.OrderExportExcel({
    IdSejour: sejour.value!.Id,
    Data: props.compiledIngredients,
    Mapping: merged,
  });
  if (res === undefined) return;

  emit("done");

  controller.showMessage("Fichier téléchargé avec succès.");

  saveBlobAsFile(res.blob, res.filename);
}

const profiles = ref<ProfileHeader[]>([]);
async function fetchProfiles() {
  const res = await controller.OrderGetProfiles();
  if (res === undefined) return;
  profiles.value = res || [];
}
</script>

<style></style>
