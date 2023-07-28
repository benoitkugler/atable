<template>
  <v-chip
    v-if="props.people != 0"
    :size="props.small ? 'small' : undefined"
    color="secondary"
  >
    {{ props.people >= 0 ? "+" : "" }}
    {{ props.people }}
    <template v-if="!props.small">p.</template>
  </v-chip>
</template>

<script lang="ts" setup>
const props = defineProps<{
  people: number;
  small: boolean;
}>();
</script>

<style></style>
