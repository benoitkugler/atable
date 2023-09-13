<template>
  <v-card
    class="py-2"
    title="Liste des ingrédients disponibles"
    :subtitle="`${ingList.length} ingrédients`"
  >
    <v-dialog
      :model-value="toEdit != null"
      @update:model-value="toEdit = null"
      max-width="600px"
    >
      <IngredientEditor
        v-if="toEdit != null"
        :ingredient="toEdit"
        @update="
          (v) => {
            toEdit = v;
            updateIngredient();
          }
        "
      ></IngredientEditor>
    </v-dialog>
    <v-card-text>
      <v-virtual-scroll :items="ingList" height="400px">
        <template v-slot:default="{ item }">
          <v-row no-gutters class="my-2">
            <v-col cols="6" align-self="center">{{ item.Name }}</v-col>
            <v-col cols="4" align-self="center">{{
              IngredientKindLabels[item.Kind]
            }}</v-col>
            <v-col cols="2" align-self="center" class="text-center">
              <v-icon v-if="controller.idUser != item.Owner">mdi-lock</v-icon>
              <template v-else>
                <v-btn icon size="x-small" @click="toEdit = copy(item)">
                  <v-icon>mdi-pencil</v-icon>
                </v-btn>
                <v-btn
                  icon
                  size="x-small"
                  class="mx-1"
                  @click="deleteIngredient(item.Id)"
                >
                  <v-icon color="red">mdi-delete</v-icon>
                </v-btn>
              </template>
            </v-col>
          </v-row>
        </template>
      </v-virtual-scroll>
    </v-card-text>
  </v-card>
</template>

<script setup lang="ts">
import { Ingredient, IdIngredient } from "@/logic/api_gen";
import { IngredientKindLabels, type Ingredients } from "@/logic/api_gen";
import { controller, copy } from "@/logic/controller";
import { computed } from "vue";
import { onMounted } from "vue";
import { ref } from "vue";
import IngredientEditor from "../IngredientEditor.vue";

// const props = defineProps<{}>();

const emit = defineEmits<{}>();

onMounted(fetchIngredients);

const ingList = computed(() => {
  const out = Object.values(ingredients.value || {});
  out.sort((a, b) => a.Name.localeCompare(b.Name));
  return out;
});

const ingredients = ref<Ingredients>({});
async function fetchIngredients() {
  const res = await controller.LibraryLoadIngredients();
  if (res === undefined) return;
  ingredients.value = res || {};
}

const toEdit = ref<Ingredient | null>(null);
async function updateIngredient() {
  const ing = toEdit.value;
  if (ing == null) return;

  toEdit.value = null;
  const res = await controller.LibraryUpdateIngredient(ing);
  if (res === undefined) return;

  ingredients.value![ing.Id] = ing;
  controller.showMessage("Ingrédient modifié avec succès.");
}

async function deleteIngredient(idIngredient: IdIngredient) {
  const res = await controller.LibraryDeleteIngredient({ idIngredient });
  if (res === undefined) return;

  if (res.Deleted) {
    delete (ingredients.value || {})[idIngredient];
    controller.showMessage("Ingrédient supprimé avec succès.");
  } else {
    controller.onError(
      "Ingrédient utilisé",
      "L'ingrédient est utilisé dans une recette ou un menu."
    );
  }
}
</script>
