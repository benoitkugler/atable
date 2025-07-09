<template>
  <v-card
    title="Associations ingrédients fournisseurs"
    subtitle="Cliquer-déplacer des ingrédients ou des catégories pour les associer à un fournisseur."
  >
    <v-dialog
      :model-value="toDelete != null"
      @update:model-value="toDelete = null"
      max-width="600px"
    >
      <v-card v-if="toDelete != null" title="Confirmer la suppression">
        <v-card-text>
          Confirmez-vous la suppression du fournisseur {{ toDelete.Name }} ?
          <br />
          Cette opération est irréversible.
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="red" variant="text" @click="deleteSupplier">
            Supprimer
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <template v-slot:append>
      <v-btn
        icon="mdi-adjust"
        size="small"
        class="mx-2"
        title="Supprimer les redondances"
        @click="tidyMapping"
      >
      </v-btn>
      <v-divider vertical></v-divider>
      <v-btn @click="addSupplier" :disabled="isReadonly"
        >Ajouter un fournisseur
        <template v-slot:prepend>
          <v-icon color="success">mdi-plus</v-icon>
        </template>
      </v-btn>

      <v-btn
        icon="mdi-close"
        variant="flat"
        class="ml-2 mr-0"
        @click="emit('close')"
      >
      </v-btn>
    </template>
    <v-card-text>
      <v-row class="fill-width">
        <v-col
          cols="6"
          md="4"
          lg="3"
          v-for="(column, index) in columns"
          :key="index"
          class="px-1"
        >
          <ProfileColumn
            :supplier="column.supplier"
            :kinds="column.kinds"
            :ingredients="column.ingredients"
            :readonly="isReadonly"
            @update="(name) => updateSupplier(column.supplier, name)"
            @delete="toDelete = column.supplier"
            @moveIngredients="moveIngredients"
            @moveKind="moveKind"
          ></ProfileColumn>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>

<script lang="ts" setup>
import {
  ProfileHeader,
  Ingredients,
  Ingredient,
  Supplier,
  IdIngredient,
  IdSupplier,
  Int,
  IdProfile,
  ProfileExt,
  IngredientKind,
} from "@/logic/api_gen";
import { controller } from "@/logic/controller";
import { computed } from "vue";
import { onMounted } from "vue";
import { ref } from "vue";
import ProfileColumn from "./ProfileColumn.vue";
import { reactive } from "vue";

const props = defineProps<{
  profile: ProfileHeader;
}>();

const emit = defineEmits<{
  (e: "close"): void;
}>();

const isReadonly = computed(
  () => props.profile.Profile.IdOwner != controller.idUser
);

const suppliers = reactive(props.profile.Suppliers || {});
const content = ref<ProfileExt>([]);
const allIngredients = ref<Ingredients>({});

onMounted(() => {
  fetchIngredients();
  fetchProfile();
});

async function fetchIngredients() {
  const res = await controller.LibraryLoadIngredients();
  if (res === undefined) return;
  allIngredients.value = res || {};
}
async function fetchProfile() {
  const res = await controller.OrderLoadProfile({
    idProfile: props.profile.Profile.Id,
  });
  if (res === undefined) return;
  content.value = res || [];
}

interface column {
  supplier: Supplier;
  kinds: IngredientKind[];
  ingredients: Ingredient[];
}

// the fist column is a factic supplier for the
// ingredients not associated yet
const columns = computed(() => {
  const cols: column[] = [];
  // compute the non associated values
  const associatedIng = new Set<IdIngredient>();
  const associatedKind = new Set<IngredientKind>();
  (content.value || []).forEach((item) => {
    (item.Kinds || []).forEach((kind) => associatedKind.add(kind));
    (item.Ingredients || []).forEach((ing) => associatedIng.add(ing));
    cols.push({
      supplier: (suppliers || {})[item.Id],
      kinds: item.Kinds || [],
      ingredients: (item.Ingredients || []).map(
        (id) => (allIngredients.value || {})[id]
      ),
    });
  });
  cols.sort((a, b) => a.supplier.Id - b.supplier.Id);
  return [
    {
      supplier: {
        Id: -1 as IdSupplier,
        Name: "Sans fournisseur",
        IdProfile: 0 as IdProfile,
      },
      kinds: Object.values(IngredientKind).filter(
        (kind) => !associatedKind.has(Number(kind) as IngredientKind)
      ),
      ingredients: Object.values(allIngredients.value || {}).filter(
        (ing) => !associatedIng.has(ing.Id)
      ),
    },
  ].concat(...cols);
});

async function addSupplier() {
  const res = await controller.OrderAddSupplier({
    Name: "Fournisseur",
    IdProfile: props.profile.Profile.Id,
    Id: 0 as IdSupplier,
  });
  if (res === undefined) return;

  suppliers[res.Id] = res;

  fetchProfile();
}

async function updateSupplier(sup: Supplier, name: string) {
  sup.Name = name;
  const res = await controller.OrderUpdateSupplier(sup);
  if (res === undefined) return;

  controller.showMessage("Fournisseur modifié avec succès.");

  suppliers[sup.Id] = sup;
}

const toDelete = ref<Supplier | null>(null);
async function deleteSupplier() {
  const sup = toDelete.value;
  if (sup == null) return;
  toDelete.value = null;
  const res = await controller.OrderDeleteSupplier({ id: sup.Id });
  if (res === undefined) return;

  controller.showMessage("Fournisseur supprimé avec succès.");

  delete suppliers[sup.Id];
  content.value = content.value!.filter((item) => item.Id != sup.Id);
}

async function moveIngredients(
  idIngredients: IdIngredient[],
  from: IdSupplier,
  to: IdSupplier
) {
  const res = await controller.OrderUpdateProfileMapIng({
    IdProfile: props.profile.Profile.Id,
    Ingredients: idIngredients,
    NewSupplier: to,
  });
  if (res === undefined) return;

  controller.showMessage("Associations modifiées avec succès.");

  content.value = res || [];
}

async function moveKind(
  kinds: IngredientKind[],
  from: IdSupplier,
  to: IdSupplier
) {
  const res = await controller.OrderUpdateProfileMapKind({
    IdProfile: props.profile.Profile.Id,
    Kinds: kinds,
    Supplier: to,
  });
  if (res === undefined) return;

  controller.showMessage("Associations modifiées avec succès.");

  content.value = res || [];
}

async function tidyMapping() {
  const res = await controller.OrderTidyMapping({
    Id: props.profile.Profile.Id,
  });
  if (res === undefined) return;
  controller.showMessage("Associations simplifiées avec succès.");

  content.value = res || [];
}
</script>

<style>
.fill-width {
  overflow-x: auto;
  flex-wrap: nowrap;
}
</style>
