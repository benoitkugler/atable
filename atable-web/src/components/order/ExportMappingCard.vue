<template>
  <v-dialog v-model="showEditMap" max-width="800px">
    <v-card
      title="Fournisseurs"
      subtitle="Choisir les fournisseurs pour cet export."
    >
      <v-card-text>
        <v-select
          class="mt-2"
          variant="outlined"
          density="compact"
          label="Profil de base"
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
        <v-expansion-panels>
          <v-expansion-panel v-if="mapping.baseProfile != null">
            <template v-slot:title>
              Associations personnalisées
              <v-badge
                class="ml-2"
                inline
                :content="mapping.customMapping.size"
              >
              </v-badge>
            </template>
            <template v-slot:text>
              <v-list>
                <v-list-item title="Ingrédient">
                  <template v-slot:append> Fournisseur </template>
                </v-list-item>
                <v-list-item
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
                        <v-chip v-on="{ isActive }" v-bind="props">
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
            </template>
          </v-expansion-panel>
        </v-expansion-panels>
      </v-card-text>
    </v-card>
  </v-dialog>

  <v-card
    title="Exporter"
    subtitle="Associer les fournisseurs et exporter au format Excel"
  >
    <v-card-text>
      <v-list-item
        class="bg-secondary-lighten"
        @click="showEditMap = true"
        rounded
        :title="
          mapping.baseProfile
            ? mapping.baseProfile.Profile.Name
            : 'Aucun profil'
        "
        :subtitle="
          mapping.baseProfile
            ? formatSuppliers(mapping.baseProfile.Suppliers)
            : ''
        "
      >
        <template v-slot:append>
          <v-badge
            inline
            v-if="mapping.customMapping.size"
            :content="`+ ${mapping.customMapping.size}`"
          >
          </v-badge>
        </template>
      </v-list-item>
    </v-card-text>
    <v-card-actions>
      <v-spacer> </v-spacer>
      <v-btn @click="downloadExcel" :disabled="sejour == null">Exporter</v-btn>
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
} from "@/logic/api_gen";
import {
  OrderIngredientMapping,
  controller,
  formatSuppliers,
  saveBlobAsFile,
} from "@/logic/controller";
import { computed } from "vue";
import { reactive } from "vue";
import { onMounted } from "vue";
import { ref } from "vue";

const props = defineProps<{
  compiledIngredients: CompileIngredientsOut;
}>();

const emit = defineEmits<{}>();

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

const showEditMap = ref(false);

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

  const res = await controller.OrderLoadProfile({
    idProfile: bp.Profile.Id,
  });
  if (res == undefined) return;

  res.forEach((item) => {
    const idSupplier = item.K;
    item.V?.forEach((idIngredient) => {
      currentProfileContent.value.set(idIngredient, idSupplier);
    });
  });
}

const profiles = ref<ProfileHeader[]>([]);

async function fetchProfiles() {
  const res = await controller.OrderGetProfiles();
  if (res === undefined) return;
  profiles.value = res || [];
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

  controller.showMessage("Fichier téléchargé avec succès.");

  saveBlobAsFile(res.blob, res.filename);
}
</script>

<style></style>
