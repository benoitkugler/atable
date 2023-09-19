<template>
  <v-card
    @dragover="onDragover"
    @dragleave="isDraggingOver = false"
    @drop="(ev) => onDrop(ev)"
    :class="{ 'bg-blue-lighten-4': isDraggingOver }"
  >
    <v-row no-gutters>
      <v-col
        align-self="center"
        :cols="toEdit == null ? 'auto' : '11'"
        class="mt-2 px-2"
        @click="
          hasEditableTitle && !props.readonly
            ? (toEdit = props.supplier.Name)
            : null
        "
      >
        <div
          v-if="toEdit == null"
          :class="{
            'text-subtitle-2': true,
            'px-1': true,
            title: hasEditableTitle && !props.readonly,
          }"
        >
          {{ props.supplier.Name }}
        </div>
        <v-text-field
          v-else
          autofocus
          @focus="$event.target.select()"
          v-model="toEdit"
          density="compact"
          variant="outlined"
          hide-details
          @blur="onBlur"
        ></v-text-field>
      </v-col>
      <v-spacer></v-spacer>
      <v-col
        cols="auto"
        align-self="center"
        v-if="hasEditableTitle && toEdit == null"
      >
        <v-btn
          icon
          size="x-small"
          class="ma-2"
          @click="emit('delete')"
          :disabled="props.readonly"
        >
          <v-icon color="red">mdi-delete</v-icon>
        </v-btn>
      </v-col>
    </v-row>
    <v-card-text class="py-1 pr-3 pl-1">
      <div style="max-height: 79vh" class="overflow-y-auto">
        <v-list-item
          v-if="!byCategorie.size"
          subtitle="Aucun ingrédient."
          class="text-center"
        ></v-list-item>
        <template v-for="item in byCategorie.entries()" :key="item[0]">
          <v-list-item
            :title="IngredientKindLabels[item[0]]"
            :style="!props.readonly ? 'cursor:  grab' : ''"
            :draggable="!props.readonly"
            @dragstart=" (ev: DragEvent) => ondragCategorie(ev, item[0])  "
          >
          </v-list-item>

          <div
            v-for="(ingredient, j) in item[1]"
            :key="j"
            :style="!props.readonly ? 'cursor:  grab' : ''"
            :draggable="!props.readonly"
            @dragstart=" (ev: DragEvent) => ondragIngredient(ev, ingredient.Id) "
          >
            <v-list-item
              :subtitle="ingredient.Name"
              :value="ingredient.Id"
              class="my-1"
            >
            </v-list-item>
          </div>
        </template>
      </div>
    </v-card-text>
  </v-card>
</template>

<script lang="ts" setup>
import {
  IdIngredient,
  IdSupplier,
  Ingredient,
  IngredientKind,
  IngredientKindLabels,
  Supplier,
} from "@/logic/api_gen";
import { computed, ref } from "vue";

const props = defineProps<{
  supplier: Supplier;
  ingredients: Ingredient[];
  readonly: boolean;
}>();

const emit = defineEmits<{
  (e: "update", name: string): void;
  (e: "delete"): void;
  (
    e: "moveIngredients",
    ingredients: IdIngredient[],
    from: IdSupplier,
    to: IdSupplier
  ): void;
}>();

const hasEditableTitle = computed(() => props.supplier.Id >= 0);

const byCategorie = computed(() => {
  const out = new Map<IngredientKind, Ingredient[]>();
  props.ingredients.forEach((ing) => {
    const l = out.get(ing.Kind) || [];
    l.push(ing);
    out.set(ing.Kind, l);
  });
  out.forEach((l) => l.sort((a, b) => a.Name.localeCompare(b.Name)));
  return out;
});

const toEdit = ref<string | null>(null);
function onBlur() {
  const s = toEdit.value || "";
  toEdit.value = null;
  if (s == props.supplier.Name) return;
  emit("update", s);
}

function ondragIngredient(event: DragEvent, idIngredient: IdIngredient) {
  event.dataTransfer?.setData(
    "json/move-ingredients",
    JSON.stringify({ idIngredients: [idIngredient], from: props.supplier.Id })
  );
  event.dataTransfer!.dropEffect = "move";
}
function ondragCategorie(event: DragEvent, cat: IngredientKind) {
  const ings = byCategorie.value.get(cat)?.map((ing) => ing.Id) || [];
  event.dataTransfer?.setData(
    "json/move-ingredients",
    JSON.stringify({ idIngredients: ings, from: props.supplier.Id })
  );
  event.dataTransfer!.dropEffect = "move";
}

const isDraggingOver = ref(false);
function onDragover(event: DragEvent) {
  if (event.dataTransfer?.types?.includes("json/move-ingredients")) {
    event.preventDefault();
    event.dataTransfer!.dropEffect = "move";
    isDraggingOver.value = true;
  }
}

function onDrop(event: DragEvent) {
  const data: { idIngredients: IdIngredient[]; from: IdSupplier } = JSON.parse(
    event.dataTransfer?.getData("json/move-ingredients") || ""
  );
  isDraggingOver.value = false;
  const idSource = data.from;
  const idTarget = props.supplier.Id;
  if (idSource == idTarget) return; // avoid useless moves
  emit("moveIngredients", data.idIngredients, idSource, idTarget);
}
</script>

<style>
.title:hover {
  border: 1px solid lightgray;
  border-radius: 6px;
}

.title {
  display: inline-block;
  border: 1px solid transparent;
}
</style>
