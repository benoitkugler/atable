<template>
  <div class="ma-1 text-center py-2">
    <small v-if="props.menu == null"> Aucun repas. </small>
    <small v-else-if="!content.length"> Menu vide. </small>
    <div v-else>
      <div v-for="(item, index) in content" :key="index">
        {{ item.title }}
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { Group, MenuExt } from "@/logic/api_gen";
import { sortMenuContent } from "@/logic/controller";
import { computed } from "vue";

const props = defineProps<{
  dayOffset: number;
  group: Group;
  menu: MenuExt | null;
}>();

const content = computed(() =>
  props.menu == null ? [] : sortMenuContent(props.menu)
);
</script>

<style scoped></style>
