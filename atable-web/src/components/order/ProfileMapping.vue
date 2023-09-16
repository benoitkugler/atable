<template>
  <v-card title="Associations ingrédients fournisseurs">
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
        @click="addSupplier"
        :disabled="props.profile.Profile.IdOwner != controller.idUser"
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
          cols="4"
          md="3"
          lg="2"
          v-for="(column, index) in columns"
          :key="index"
          class="px-1"
        >
          <ProfileColumn
            :supplier="column.supplier"
            :ingredients="column.ingredients"
            @update="(name) => updateSupplier(column.supplier, name)"
            @delete="toDelete = column.supplier"
          ></ProfileColumn>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>

<script lang="ts" setup>
import type {
  ProfileHeader,
  Mapping,
  Ingredients,
  Ingredient,
  Supplier,
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

const suppliers = reactive(props.profile.Suppliers || {});
const content = ref<Mapping>([]);
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
  ingredients: Ingredient[];
}

// the fist column is a factic supplier for the
// ingredients not associated yet
const columns = computed(() => {
  const cols: column[] = [];
  const associated = new Set<number>();
  (content.value || []).forEach((item) => {
    item.V?.forEach(associated.add);
    cols.push({
      supplier: (suppliers || {})[item.K],
      ingredients: (item.V || []).map((id) => (allIngredients.value || {})[id]),
    });
  });
  return [
    {
      supplier: { Id: -1, Name: "Sans fournisseur", IdProfile: 0 },
      ingredients: Object.values(allIngredients.value || {}).filter(
        (ing) => !associated.has(ing.Id)
      ),
    },
  ].concat(...cols);
});

async function addSupplier() {
  const res = await controller.OrderAddSupplier({
    Name: "Fournisseur",
    IdProfile: props.profile.Profile.Id,
    Id: 0,
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
  content.value = content.value!.filter((item) => item.K != sup.Id);
}
</script>

<style>
.fill-width {
  overflow-x: auto;
  flex-wrap: nowrap;
}
</style>
