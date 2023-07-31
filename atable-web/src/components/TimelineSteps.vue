<template>
  <v-timeline direction="horizontal" side="start" density="compact">
    <v-timeline-item
      v-for="(step, index) in props.steps"
      :key="index"
      :size="index == props.currentStep ? undefined : 'small'"
      :elevation="index == props.currentStep ? 4 : undefined"
      :dot-color="index == props.currentStep ? 'primary' : 'grey'"
      fill-dot
    >
      <template v-slot:icon>
        {{ index + 1 }}
      </template>
    </v-timeline-item>
  </v-timeline>
</template>

<script lang="ts" setup>
const props = defineProps<{
  steps: string[];
  currentStep: number;
}>();

const emit = defineEmits<{}>();
</script>
