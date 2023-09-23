<template>
  <v-list style="max-height: 72vh" class="overflow-y-auto">
    <div v-if="!ingredients.Ingredients?.length" class="text-center">
      <i>Aucun ingrédient.</i>
    </div>

    <template v-for="kind in byKind" :key="kind.kind">
      <v-list-subheader>{{ IngredientKindLabels[kind.kind] }}</v-list-subheader>
      <v-list-item v-for="ing in kind.ingredients" :key="ing.Ingredient.Id">
        {{ ing.Ingredient.Name }}
        <template v-slot:append>
          <v-menu :eager="false" location="bottom end">
            <template v-slot:activator="{ isActive, props }">
              <v-chip v-on="{ isActive }" v-bind="props">
                {{ aggregateQuantities(ing.Quantities || []) }}
              </v-chip>
            </template>
            <v-card density="compact">
              <v-card-text>
                <v-list>
                  <v-list-item
                    v-for="(use, index) in ing.Quantities"
                    :key="index"
                  >
                    <v-list-item-title>
                      <RouterLink
                        variant="text"
                        :to="{
                          name: 'agenda',
                          query: { dayOffset: offsetForOrigin(use.Origin) },
                        }"
                      >
                        {{ originTitle(use.Origin) }}
                      </RouterLink>
                    </v-list-item-title>
                    <v-list-item-subtitle>
                      {{ originSubtitle(use.Origin) }}
                    </v-list-item-subtitle>
                    <template v-slot:append>
                      <div class="ml-4">
                        {{ formatQuantity(use.Quantity) }}
                      </div>
                    </template>
                  </v-list-item>
                </v-list>
              </v-card-text>
            </v-card>
          </v-menu>
        </template>
      </v-list-item>
    </template>
  </v-list>
</template>

<script lang="ts" setup>
import { HoraireLabels, IdMeal, IngredientQuantities } from "@/logic/api_gen";
import {
  type CompileIngredientsOut,
  IngredientKindLabels,
  IngredientKind,
} from "@/logic/api_gen";
import {
  addDays,
  aggregateQuantities,
  controller,
  formatDate,
  formatQuantity,
} from "@/logic/controller";
import { computed } from "vue";
import { RouterLink } from "vue-router";

const props = defineProps<{
  ingredients: CompileIngredientsOut;
}>();

const emit = defineEmits<{}>();

const sejour = computed(() => controller.activeSejour!.Sejour);

const byKind = computed(() => {
  const tmp = new Map<IngredientKind, IngredientQuantities[]>();
  props.ingredients.Ingredients?.forEach((ing) => {
    const l = tmp.get(ing.Ingredient.Kind) || [];
    l.push(ing);
    tmp.set(ing.Ingredient.Kind, l);
  });
  for (const l of tmp.values()) {
    l.sort((a, b) => a.Ingredient.Name.localeCompare(b.Ingredient.Name));
  }
  return Array.from(tmp.entries()).map((l) => ({
    kind: l[0],
    ingredients: l[1],
  }));
});

function originTitle(idMeal: IdMeal) {
  const meal = (props.ingredients.Meals || {})[idMeal];
  const date = addDays(new Date(sejour.value.Start), meal.Jour);
  return formatDate(date);
}
function originSubtitle(idMeal: IdMeal) {
  const meal = (props.ingredients.Meals || {})[idMeal];
  return HoraireLabels[meal.Horaire];
}

function offsetForOrigin(idMeal: IdMeal) {
  const meal = (props.ingredients.Meals || {})[idMeal];
  return meal.Jour;
}
</script>
