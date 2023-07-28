<template>
  <v-list-item
    density="compact"
    :draggable="true"
    @dragstart="onDrag"
    rounded
    class="pl-0"
  >
    <template v-slot:prepend>
      <v-icon style="cursor: grab" class="ml-0 mr-1 px-0">
        mdi-drag-vertical
      </v-icon>
    </template>
    <v-list-item-title>{{ props.title }}</v-list-item-title>
    <v-list-item-subtitle v-if="props.subtitle.length">
      {{ props.subtitle }}
    </v-list-item-subtitle>
  </v-list-item>
</template>

<script lang="ts" setup>
const props = defineProps<{
  title: string;
  subtitle: string;
}>();

const emit = defineEmits<{
  (event: "onDrag", e: DragEvent): void;
}>();

function onDrag(ev: DragEvent) {
  ev.dataTransfer!.dropEffect = "move";
  emit("onDrag", ev);
}
</script>

<style></style>
