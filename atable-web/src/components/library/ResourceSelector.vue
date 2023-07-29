<template>
  <v-autocomplete
    class="my-2 mx-2"
    density="compact"
    variant="underlined"
    menu-icon=""
    auto-select-first
    :label="label"
    append-inner-icon="mdi-magnify"
    hint="Appuyer sur Tab ou Entrée pour valider rapidement."
    persistent-hint
    :custom-filter="customFilter"
    :items="props.items"
    @update:model-value="onAdd"
    v-model:search="search"
    v-model="item"
    item-title="Title"
    item-value="Id"
    return-object
  ></v-autocomplete>
</template>

<script setup lang="ts">
import { MenuResource } from "@/logic/controller";
import { nextTick } from "vue";
import { ref } from "vue";

const props = defineProps<{
  items: MenuResource[];
  label: string;
}>();

const emit = defineEmits<{
  (e: "selected", item: MenuResource): void;
}>();

const search = ref("");
const item = ref<MenuResource | null>(null);

function customFilter(itemTitle: string, queryText: string) {
  queryText = queryText
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
  itemTitle = itemTitle
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
  const index = itemTitle.indexOf(queryText);
  return index == -1 ? false : index;
}

function onAdd(v: MenuResource | null) {
  if (v == null) return;
  emit("selected", v);
  // clear the selector
  nextTick(() => {
    search.value = "";
    item.value = null;
  });
}
</script>
