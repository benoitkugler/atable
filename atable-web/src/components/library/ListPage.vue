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
          <v-btn
            icon
            v-if="item.IsPersonnal"
            size="x-small"
            @click.stop="emit('deleteMenu', item)"
          >
            <v-icon color="red">mdi-delete</v-icon>
          </v-btn>
          <v-tooltip v-else>
            <template v-slot:activator="{ props }">
              <v-icon color="grey-lighten-1" v-bind="props" class="mr-1"
                >mdi-lock</v-icon
              >
            </template>
            Ce menu appartient à : <b>{{ item.Owner }}</b>
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
          <v-btn
            icon
            v-if="item.IsPersonnal"
            size="x-small"
            @click.stop="emit('deleteReceipe', item)"
          >
            <v-icon color="red">mdi-delete</v-icon>
          </v-btn>
          <v-tooltip v-else>
            <template v-slot:activator="{ props }">
              <v-icon color="grey-lighten-1" v-bind="props" class="mr-1"
                >mdi-lock</v-icon
              >
            </template>
            Cette recette appartient à
            <b>{{ item.Owner }}</b>
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
  ReceipeHeader,
  ResourceHeader,
  ResourceSearchOut,
} from "@/logic/api_gen";
import { PlatKindLabels } from "@/logic/api_gen";

const props = defineProps<{
  resources: ResourceSearchOut;
}>();

const emit = defineEmits<{
  (e: "updateMenu", m: ResourceHeader): void;
  (e: "updateReceipe", m: ReceipeHeader): void;
  (e: "deleteMenu", m: ResourceHeader): void;
  (e: "deleteReceipe", m: ReceipeHeader): void;
}>();
</script>
