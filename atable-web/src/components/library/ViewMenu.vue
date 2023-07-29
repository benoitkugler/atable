<template>
  <v-card>
    <v-row no-gutters>
      <v-col align-self="center">
        <v-btn flat @click="emit('back')" class="mx-2">
          <template v-slot:prepend>
            <v-icon>mdi-arrow-left</v-icon>
            Retour à la liste
          </template>
        </v-btn>
      </v-col>
      <v-col align-self="center">
        <v-card-title v-if="isReadonly">
          Détails du menu
          <v-icon size="small">mdi-lock</v-icon>
        </v-card-title>
        <v-card-title v-else> Modifier le menu </v-card-title>
      </v-col>
    </v-row>

    <v-card-text v-if="inner != null">
      <v-row>
        <v-col>
          <v-card>
            <v-row>
              <v-col align-self="center">
                <v-card-title> Recettes et ingrédients </v-card-title>
                <v-card-subtitle
                  v-if="inner.Ingredients?.length && hasSameForPeople != null"
                >
                  Ingrédients pour {{ hasSameForPeople }} personnes
                </v-card-subtitle>
              </v-col>
              <v-col cols="7" v-if="!isReadonly">
                <ResourceSelector
                  :items="resourcesDB"
                  label="Ajouter une recette ou un ingrédient"
                  @selected="addResource"
                ></ResourceSelector>
              </v-col>
            </v-row>
            <v-card-text>
              <div v-if="!sortedItems.length" class="text-center">
                <i>Le menu est vide.</i>
              </div>
              <v-list density="compact" style="column-count: 2">
                <v-card
                  v-for="(item, index) in sortedItems"
                  :key="index"
                  elevation="0"
                  variant="outlined"
                  :color="platColors[item.plat]"
                  class="mb-2 mx-1 pa-2"
                >
                  <v-row
                    style="break-inside: avoid-column"
                    no-gutters
                    justify="space-between"
                  >
                    <v-col align-self="center" class="pl-1">
                      <v-list-item-title>
                        <v-chip
                          class="px-2"
                          variant="text"
                          @[item.isReceipe&&`click`]="goTo(item)"
                        >
                          {{ item.title }}
                        </v-chip>
                      </v-list-item-title>
                      <v-list-item-subtitle>
                        <v-chip
                          v-if="item.isReceipe"
                          density="compact"
                          class="px-2"
                          variant="text"
                        >
                          {{ PlatKindLabels[item.plat] }}
                        </v-chip>
                        <v-menu v-else>
                          <template v-slot:activator="{ isActive, props }">
                            <v-chip
                              v-on="{ isActive }"
                              v-bind="props"
                              density="compact"
                              class="px-2"
                              variant="text"
                            >
                              {{ PlatKindLabels[item.plat] }}
                            </v-chip>
                          </template>
                          <v-list>
                            <v-list-item
                              v-for="kind in platItems"
                              :key="kind.plat"
                              @click="updatePlat(item, kind.plat)"
                            >
                              {{ kind.title }}
                            </v-list-item>
                          </v-list>
                        </v-menu>
                      </v-list-item-subtitle>
                    </v-col>
                    <v-col align-self="center" cols="auto">
                      <QuantityChip
                        v-if="item.quantity != undefined"
                        :quantity="item.quantity"
                        :show-for="hasSameForPeople == null"
                        :disabled="isReadonly"
                        @update="(qu) => updateIngredient(item, qu)"
                      ></QuantityChip>
                    </v-col>
                    <v-col cols="auto" align-self="center" class="pl-4">
                      <v-btn
                        icon
                        color="white"
                        size="x-small"
                        @click="deleteResource(item)"
                        :disabled="isReadonly"
                      >
                        <v-icon color="red">mdi-delete</v-icon>
                      </v-btn>
                    </v-col>
                  </v-row>
                </v-card>
              </v-list>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>

<script setup lang="ts">
import { QuantityR, MenuExt, IdReceipe, IdMenu } from "@/logic/api_gen";
import { MenuResource, controller, MenuItem } from "@/logic/controller";
import { onMounted } from "vue";
import { ref } from "vue";
import ResourceSelector from "./ResourceSelector.vue";
import { computed } from "vue";
import { sortMenuContent, platColors } from "@/logic/controller";
import { IdIngredient } from "@/logic/api_gen";
import { PlatKindLabels } from "@/logic/api_gen";
import QuantityChip from "./QuantityChip.vue";
import { PlatKind } from "@/logic/api_gen";

interface Props {
  menu: IdMenu;
}

const props = defineProps<Props>();

const emit = defineEmits<{
  (event: "back"): void;
  (event: "goToReceipe", id: IdReceipe): void;
}>();

onMounted(fetch);

const inner = ref<MenuExt | null>(null);
const resourcesDB = ref<MenuResource[]>([]);

const isReadonly = computed(() => inner.value?.Owner != controller.idUser);

const sortedItems = computed(() =>
  inner.value == null ? [] : sortMenuContent(inner.value)
);

const platItems = Object.entries(PlatKindLabels).map((ent) => ({
  plat: Number(ent[0]) as PlatKind,
  title: ent[1],
}));
platItems.sort((a, b) => -(a.plat - b.plat));

async function fetch() {
  const res = await controller.LibraryLoadMenu({
    idMenu: props.menu,
  });
  if (res === undefined) return;
  inner.value = res;

  const ings = await controller.LibraryLoadIngredients();
  if (ings === undefined) return;
  resourcesDB.value = Object.values(ings || {}).map((ing) => ({
    Title: ing.Name,
    Id: ing.Id,
    Kind: "ingredient",
  }));
  const recs = await controller.LibraryLoadReceipes();
  if (recs === undefined) return;
  resourcesDB.value.push(
    ...Object.values(recs || {}).map((rec) => ({
      Title: rec.Name,
      Id: rec.Id,
      Kind: "receipe" as const,
    }))
  );
}

async function addResource(item: MenuResource) {
  if (item.Kind == "ingredient") {
    addIngredient(item);
  } else {
    addReceipe(item);
  }
}

async function addIngredient(item: MenuResource) {
  if (
    inner.value?.Ingredients?.find((ing) => ing.IdIngredient == item.Id) !=
    undefined
  )
    return;

  const res = await controller.LibraryAddMenuIngredient({
    IdMenu: props.menu,
    IdIngredient: item.Id,
  });
  if (res == undefined) return;

  controller.showMessage("Ingrédient ajouté avec succès.");
  inner.value!.Ingredients = (inner.value?.Ingredients || []).concat(res);
}
async function addReceipe(item: MenuResource) {
  if (inner.value?.Receipes?.find((ing) => ing.Id == item.Id) != undefined)
    return;

  const res = await controller.LibraryAddMenuReceipe({
    IdMenu: props.menu,
    IdReceipe: item.Id,
  });
  if (res == undefined) return;

  controller.showMessage("Recette ajoutée avec succès.");
  inner.value!.Receipes = (inner.value?.Receipes || []).concat(res);
}

const hasSameForPeople = computed(() => {
  const s = new Set(inner.value?.Ingredients?.map((ing) => ing.Quantity.For));
  return s.size == 1 ? Array.from(s.keys())[0] : null;
});

async function updateIngredient(item: MenuItem, qu: QuantityR) {
  const res = await controller.LibraryUpdateMenuIngredient({
    IdIngredient: item.id,
    IdMenu: props.menu,
    Quantity: qu,
    Plat: item.plat,
  });
  if (res === undefined) return;
  controller.showMessage("Quantité modifiée avec succès.");
  const toChange = inner.value?.Ingredients?.find(
    (ing) => ing.IdIngredient == item.id
  )!;
  toChange.Quantity = qu;
}

async function updatePlat(item: MenuItem, plat: PlatKind) {
  const res = await controller.LibraryUpdateMenuIngredient({
    IdIngredient: item.id,
    IdMenu: props.menu,
    Quantity: item.quantity!,
    Plat: plat,
  });
  if (res === undefined) return;
  controller.showMessage("Type de plat modifié avec succès.");
  const toChange = inner.value?.Ingredients?.find(
    (ing) => ing.IdIngredient == item.id
  )!;
  toChange.Plat = plat;
}

function deleteResource(item: MenuItem) {
  if (item.isReceipe) {
    deleteReceipe(item.id);
  } else {
    deleteIngredient(item.id);
  }
}

async function deleteIngredient(id: IdIngredient) {
  const res = await controller.LibraryDeleteMenuIngredient({
    idMenu: props.menu,
    idIngredient: id,
  });
  if (res === undefined) return;
  controller.showMessage("Ingrédient retiré avec succès.");
  inner.value!.Ingredients = (inner.value?.Ingredients || []).filter(
    (ing) => ing.IdIngredient != id
  );
}
async function deleteReceipe(id: IdReceipe) {
  const res = await controller.LibraryDeleteMenuReceipe({
    idMenu: props.menu,
    idReceipe: id,
  });
  if (res === undefined) return;
  controller.showMessage("Ingrédient retiré avec succès.");
  inner.value!.Receipes = (inner.value?.Receipes || []).filter(
    (rec) => rec.Id != id
  );
}

function goTo(item: MenuItem) {
  emit("goToReceipe", item.id);
}
</script>
