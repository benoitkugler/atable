<template>
  <v-select
    variant="outlined"
    density="compact"
    label="Unité"
    hide-details
    :items="items"
    :model-value="props.modelValue"
    @update:model-value="(v) => emit('update:model-value', v)"
  ></v-select>
</template>

<script lang="ts" setup>
import { Unite, UniteLabels } from "@/logic/api_gen";

const props = defineProps<{
  modelValue: Unite;
}>();

const emit = defineEmits<{
  (event: "update:model-value", v: Unite): void;
}>();

const items = Object.entries(UniteLabels).map((l) => ({
  value: Number(l[0]) as Unite,
  title: l[1],
}));
</script>
