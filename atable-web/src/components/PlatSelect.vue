<template>
  <v-select
    variant="outlined"
    density="compact"
    label="Plat"
    hide-details
    :items="items"
    :model-value="props.modelValue"
    @update:model-value="(v) => emit('update:model-value', v)"
    :disabled="disabled"
  ></v-select>
</template>

<script lang="ts" setup>
import { PlatKind, PlatKindLabels } from "@/logic/api_gen";

const props = defineProps<{
  modelValue: PlatKind;
  disabled?: boolean;
}>();

const emit = defineEmits<{
  (event: "update:model-value", v: PlatKind): void;
}>();

const items = Object.entries(PlatKindLabels).map((l) => ({
  value: Number(l[0]) as PlatKind,
  title: l[1],
}));
items.sort((a, b) => -(a.value - b.value));
</script>
