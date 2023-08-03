<template>
  <v-chip
    :color="props.isMonoGroup ? undefined : props.group.Color"
    class="mx-0"
    :variant="props.isHovering ? 'elevated' : undefined"
    >{{ sigle }}</v-chip
  >
</template>

<script lang="ts" setup>
import { Group } from "@/logic/api_gen";
import { computed } from "vue";

const props = defineProps<{
  group: Group;
  isMonoGroup: boolean;
  small: boolean;
  isHovering?: boolean;
}>();

const sigle = computed(() => {
  if (props.isMonoGroup) return "Tous";
  const name = props.group.Name;
  if (name == "") return "...";
  return props.small
    ? name.substring(0, 1).toUpperCase() + name.substring(1, 2)
    : name;
});
</script>
