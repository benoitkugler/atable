<template>
  <v-card title="Détails de l'ingrédient">
    <v-card-text>
      <v-form>
        <v-row>
          <v-col>
            <v-text-field
              v-model="inner.Name"
              label="Nom"
              variant="outlined"
              density="compact"
              autofocus
              hide-details
            >
            </v-text-field>
          </v-col>
        </v-row>
        <v-row>
          <v-col>
            <IngredientKindSelect v-model="inner.Kind"></IngredientKindSelect>
          </v-col>
        </v-row>
      </v-form>
    </v-card-text>
    <v-card-actions>
      <v-spacer></v-spacer>
      <v-btn color="success" @click="emit('update', inner)">Enregistrer</v-btn>
    </v-card-actions>
  </v-card>
</template>

<script setup lang="ts">
import type { Ingredient } from "@/logic/api_gen";
import { copy } from "@/logic/controller";
import { ref } from "vue";
import IngredientKindSelect from "../IngredientKindSelect.vue";

const props = defineProps<{
  ingredient: Ingredient;
}>();

const emit = defineEmits<{
  (e: "update", q: Ingredient): void;
}>();

const inner = ref(copy(props.ingredient));
</script>
