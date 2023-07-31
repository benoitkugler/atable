<template>
  <v-card-text>
    <v-virtual-scroll :items="toMap" height="400">
      <template v-slot:default="{ item, index }">
        <v-list-item variant="outlined" rounded class="my-1">
          <v-row>
            <v-col align-self="center">{{ item.key }}</v-col>
            <v-col cols="auto" align-self="center">
              <v-icon>mdi-chevron-right</v-icon>
            </v-col>
            <v-col>
              <ResourceSelector
                v-if="indexToEdit == index"
                label="Ingrédient à associer"
                :items="props.ingredients"
                @selected="(ing) => updateMap(index, ing)"
                @create-ingredient="(ing) => updateMapNew(index, ing)"
              ></ResourceSelector>
              <v-card v-else>
                <v-row no-gutters>
                  <v-col cols="auto">
                    <v-list-item-title> {{ item.ing.Name }}</v-list-item-title>
                    <v-list-item-subtitle>
                      {{
                        IngredientKindLabels[item.ing.Kind]
                      }}</v-list-item-subtitle
                    >
                  </v-col>
                  <v-col cols="auto" align-self="center" class="ml-2">
                    <v-icon color="secondary" v-if="item.ing.Id == -1"
                      >mdi-new-box</v-icon
                    >
                  </v-col>
                </v-row>
              </v-card>
            </v-col>
            <v-col cols="auto" align-self="center">
              <v-btn
                icon
                size="small"
                variant="flat"
                @click="indexToEdit = -1"
                v-if="indexToEdit == index"
              >
                <v-icon> mdi-close </v-icon>
              </v-btn>
              <v-btn
                icon
                size="small"
                variant="flat"
                @click="editItem(index)"
                v-else
              >
                <v-icon> mdi-pencil </v-icon>
              </v-btn>
            </v-col>
          </v-row>
        </v-list-item>
      </template>
    </v-virtual-scroll>
  </v-card-text>
  <v-card-actions>
    <v-btn flat @click="emit('back')">Retour</v-btn>
    <v-spacer></v-spacer>
    <v-btn
      color="success"
      flat
      @click="
        emit(
          'showReceipes',
          Object.fromEntries(toMap.map((v) => [v.key, v.ing]))
        )
      "
    >
      Continuer
    </v-btn>
  </v-card-actions>
</template>

<script setup lang="ts">
import {
  ImportReceipes1Out,
  Ingredient,
  IngredientKindLabels,
} from "@/logic/api_gen";
import { ref } from "vue";
import ResourceSelector from "./ResourceSelector.vue";
import { MenuResource } from "@/logic/controller";

const props = defineProps<{
  receipes: ImportReceipes1Out;
  ingredients: MenuResource[];
}>();

const emit = defineEmits<{
  (e: "back"): void;
  (e: "showReceipes", map: { [key: string]: Ingredient }): void;
}>();

const toMap = ref(
  Object.entries(props.receipes.Map || {}).map((l) => ({
    key: l[0],
    ing: l[1],
  }))
);

const indexToEdit = ref(-1);
function editItem(index: number) {
  indexToEdit.value = index;
}

function updateMap(index: number, ing: MenuResource) {
  toMap.value[index].ing = {
    Id: ing.Id,
    Name: ing.Title,
    Kind: ing.IngredientKind!,
  };
  indexToEdit.value = -1;
}

function updateMapNew(index: number, ing: Ingredient) {
  toMap.value[index].ing = {
    Id: -1, // mark as new
    Name: ing.Name,
    Kind: ing.Kind,
  };
  indexToEdit.value = -1;
}
</script>
