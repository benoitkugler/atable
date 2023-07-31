<template>
  <v-select
    variant="outlined"
    density="compact"
    label="Catégorie"
    hide-details
    :items="items"
    :model-value="props.modelValue"
    @update:model-value="(v) => emit('update:model-value', v)"
    :disabled="disabled"
  ></v-select>
</template>

<script lang="ts" setup>
import { IngredientKind, IngredientKindLabels } from "@/logic/api_gen";

const props = defineProps<{
  modelValue: IngredientKind;
  disabled?: boolean;
}>();

const emit = defineEmits<{
  (event: "update:model-value", v: IngredientKind): void;
}>();

const items = Object.entries(IngredientKindLabels).map((l) => ({
  value: Number(l[0]) as IngredientKind,
  title: l[1],
}));
items.sort((a, b) => -(a.value - b.value));
</script>
