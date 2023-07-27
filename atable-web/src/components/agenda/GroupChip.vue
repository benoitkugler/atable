<template>
  <v-chip :color="props.group.Color" class="mx-0" size="small">{{
    sigle
  }}</v-chip>
</template>

<script lang="ts" setup>
import { Group } from "@/logic/api_gen";
import { computed } from "vue";

const props = defineProps<{
  group: Group;
}>();

const sigle = computed(() => {
  const name = props.group.Name;
  if (name == "") return "To";
  return name.substring(0, 1).toUpperCase() + name.substring(1, 2);
});
</script>
