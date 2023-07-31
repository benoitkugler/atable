<template>
  <v-card
    :style="{
      'column-count': 2,
    }"
    class="py-2"
  >
    <!-- Menus -->
    <template v-if="resources.Menus?.length">
      <v-list-subheader>Menus favoris</v-list-subheader>

      <v-list-item
        class="ma-1 bg-grey-lighten-5"
        style="break-inside: avoid-column"
        density="comfortable"
        rounded
        v-for="(item, index) in resources.Menus"
        :key="index"
        @click="emit('updateMenu', item)"
      >
        <template v-slot:append>
          <v-tooltip
            v-if="!item.IsPersonnal"
            text="Ce menu vient de la base officielle."
          >
            <template v-slot:activator="{ isActive, props }">
              <v-icon color="grey-lighten-1" v-on="{ isActive }" v-bind="props"
                >mdi-lock</v-icon
              >
            </template>
          </v-tooltip>
        </template>

        <v-list-item-title>{{
          item.Title || `Menu ${item.ID}`
        }}</v-list-item-title>
      </v-list-item>

      <v-divider class="my-1"></v-divider>
    </template>
    <!-- Receipes -->
    <template v-if="resources.Receipes?.length">
      <v-list-subheader>Recettes</v-list-subheader>

      <v-list-item
        class="ma-1 bg-grey-lighten-5"
        style="break-inside: avoid-column"
        density="comfortable"
        rounded
        v-for="(item, index) in resources.Receipes"
        :key="index"
        @click="emit('updateReceipe', item)"
      >
        <template v-slot:append>
          <v-tooltip
            v-if="!item.IsPersonnal"
            text="Cette recette vient de la base officielle."
          >
            <template v-slot:activator="{ isActive, props }">
              <v-icon color="grey-lighten-1" v-on="{ isActive }" v-bind="props"
                >mdi-lock</v-icon
              >
            </template>
          </v-tooltip>
        </template>

        <v-list-item-title>{{ item.Title }}</v-list-item-title>
        <v-list-item-subtitle>
          {{ PlatKindLabels[item.Plat] }}
        </v-list-item-subtitle>
      </v-list-item>
    </template>
  </v-card>
</template>

<script setup lang="ts">
import type {
  Date_,
  ReceipeHeader,
  ResourceHeader,
  ResourceSearchOut,
} from "@/logic/api_gen";
import { PlatKindLabels } from "@/logic/api_gen";
import { computed } from "vue";

const props = defineProps<{
  resources: ResourceSearchOut;
}>();

const emit = defineEmits<{
  (e: "updateMenu", m: ResourceHeader): void;
  (e: "updateReceipe", m: ReceipeHeader): void;
}>();

const pageSize = computed(
  () =>
    (props.resources.Menus?.length || 0) +
    (props.resources.Ingredients?.length || 0)
);
</script>
