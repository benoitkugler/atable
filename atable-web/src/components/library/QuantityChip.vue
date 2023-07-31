<template>
  <v-menu :close-on-content-click="false" v-model="showMenu">
    <template v-slot:activator="{ isActive, props: innerProps }">
      <v-chip
        v-on="{ isActive }"
        v-bind="innerProps"
        color="secondary"
        elevation="1"
        :disabled="props.disabled"
      >
        <b>{{ quantity.Val }}</b
        >&nbsp;
        {{ UniteLabels[quantity.Unite] }}
        <template v-if="props.showFor">(pour {{ quantity.For_ }})</template>
      </v-chip>
    </template>
    <QuantityEditor :quantity="quantity" @update="save"></QuantityEditor>
  </v-menu>
</template>

<script setup lang="ts">
import { UniteLabels, type QuantityR } from "@/logic/api_gen";
import { ref } from "vue";
import QuantityEditor from "./QuantityEditor.vue";

const props = defineProps<{
  quantity: QuantityR;
  showFor: boolean;
  disabled: boolean;
}>();

const emit = defineEmits<{
  (e: "update", q: QuantityR): void;
}>();

const showMenu = ref(false);

function save(quantity: QuantityR) {
  showMenu.value = false;
  emit("update", quantity);
}
</script>
