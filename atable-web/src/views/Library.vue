<template>
  <v-container fluid>
    <view-list
      v-if="viewMode == 'list'"
      v-model:page-index="pageIndex"
      v-model:search-pattern="searchPattern"
      @update-menu="
        (m) => {
          currentMenu = m.ID;
          viewMode = 'menu';
        }
      "
      @update-receipe="
        (m) => {
          currentReceipe = m.ID;
          viewMode = 'receipe';
        }
      "
    ></view-list>
    <view-menu
      v-else-if="viewMode == 'menu'"
      :menu="currentMenu!"
      @back="viewMode = 'list'"
      @go-to-receipe="goToReceipe"
    ></view-menu>
    <view-receipe
      v-else-if="viewMode == 'receipe'"
      :receipe="currentReceipe!"
      @back="viewMode = 'list'"
    ></view-receipe>
  </v-container>
</template>

<script lang="ts" setup>
import ViewList from "@/components/library/ViewList.vue";
import ViewMenu from "@/components/library/ViewMenu.vue";
import ViewReceipe from "@/components/library/ViewReceipe.vue";
import { IdMenu, IdReceipe } from "@/logic/api_gen";
import { onMounted } from "vue";

import { ref } from "vue";
import { useRoute } from "vue-router";

const viewMode = ref<"list" | "menu" | "receipe">("list");
const currentMenu = ref<IdMenu | null>(null);
const currentReceipe = ref<IdReceipe | null>(null);

const pageIndex = ref(1);
const searchPattern = ref("");

function goToReceipe(id: IdReceipe) {
  currentReceipe.value = id;
  viewMode.value = "receipe";
}

const route = useRoute();
onMounted(() => {
  const idMenu = route.query["id-menu"];
  const idReceipe = route.query["id-receipe"];
  if (idMenu) {
    currentMenu.value = Number(idMenu) as IdMenu;
    viewMode.value = "menu";
  } else if (idReceipe) {
    currentReceipe.value = Number(idReceipe) as IdReceipe;
    viewMode.value = "receipe";
  }
});
</script>
