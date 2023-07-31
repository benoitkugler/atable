<template>
  <v-card-text>
    <v-list class="mx-auto" width="500">
      <v-card
        v-for="(receipe, index) in props.receipes.Receipes"
        :key="index"
        class="my-1"
        :title="receipe.Name"
        :color="platColors[receipe.Plat]"
        variant="tonal"
        :subtitle="PlatKindLabels[receipe.Plat]"
        density="compact"
      >
        <template v-slot:append>
          Pour
          <b>
            {{ receipe.For }}
          </b>
          per.
        </template>
        <v-card-text class="pa-0">
          <v-list>
            <v-list-item
              v-for="ing in receipe.Ingredients"
              :key="ing.Name"
              density="compact"
              class="my-0 py-0"
            >
              <v-row no-gutters>
                <v-col>{{ (props.receipes.Map || {})[ing.Name].Name }}</v-col>
                <v-col cols="2" class="text-right mr-2"
                  ><b>
                    {{ ing.Quantity }}
                  </b>
                </v-col>
                <v-col cols="2">{{ UniteLabels[ing.Unite] }}</v-col>
              </v-row>
            </v-list-item>
          </v-list>
        </v-card-text>
      </v-card>
    </v-list>
  </v-card-text>
  <v-card-actions>
    <v-btn flat @click="emit('back')">Retour</v-btn>
    <v-spacer></v-spacer>
    <v-btn color="success" flat @click="emit('import')">
      Importer les recettes
    </v-btn>
  </v-card-actions>
</template>

<script setup lang="ts">
import {
  ImportReceipes1Out,
  Ingredient,
  PlatKindLabels,
  UniteLabels,
} from "@/logic/api_gen";
import { ref } from "vue";
import { MenuResource, platColors } from "@/logic/controller";

const props = defineProps<{
  receipes: ImportReceipes1Out;
}>();

const emit = defineEmits<{
  (e: "back"): void;
  (e: "import"): void;
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
