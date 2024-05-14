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
    <v-row class="mx-2 mb-2" justify="center">
      <v-col v-if="!props.kinds.length" cols="auto">
        <small class="font-italic">Déposer une catégorie...</small>
      </v-col>
      <v-col
        v-for="kind in props.kinds"
        :key="kind"
        cols="auto"
        class="px-1 py-1"
      >
        <v-chip
          link
          elevation="1"
          size="small"
          :style="!props.readonly ? 'cursor:  grab' : ''"
          :draggable="!props.readonly"
          @dragstart=" (ev: DragEvent) => ondragKind(ev, kind) "
          >{{ IngredientKindLabels[kind] }}</v-chip
        >
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
            <template v-slot:append>
              <v-btn
                variant="flat"
                size="small"
                :icon="
                  expandState.get(item[0])
                    ? 'mdi-chevron-up'
                    : 'mdi-chevron-down'
                "
                @click="expandState.set(item[0], !expandState.get(item[0]))"
              >
              </v-btn>
            </template>
          </v-list-item>

          <div v-show="expandState.get(item[0])">
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
import { reactive } from "vue";
import { computed, ref } from "vue";

const props = defineProps<{
  supplier: Supplier;
  kinds: IngredientKind[];
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
  (
    e: "moveKind",
    newKinds: IngredientKind[],
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

const expandState = reactive(new Map<IngredientKind, boolean>());

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
function ondragKind(event: DragEvent, kind: IngredientKind) {
  event.dataTransfer?.setData(
    "json/move-kind",
    JSON.stringify({ kind: kind, from: props.supplier.Id })
  );
  event.dataTransfer!.dropEffect = "move";
}

const isDraggingOver = ref(false);
function onDragover(event: DragEvent) {
  const l = event.dataTransfer?.types || [];
  if (l.includes("json/move-ingredients") || l.includes("json/move-kind")) {
    event.preventDefault();
    event.dataTransfer!.dropEffect = "move";
    isDraggingOver.value = true;
  }
}

function onDrop(event: DragEvent) {
  const idTarget = props.supplier.Id;
  isDraggingOver.value = false;

  const l = event.dataTransfer?.types || [];
  if (l.includes("json/move-ingredients")) {
    const data: { idIngredients: IdIngredient[]; from: IdSupplier } =
      JSON.parse(event.dataTransfer?.getData("json/move-ingredients") || "");
    const idSource = data.from;
    if (idSource == idTarget) return; // avoid useless moves
    emit("moveIngredients", data.idIngredients, idSource, idTarget);
  } else {
    const data: { kind: IngredientKind; from: IdSupplier } = JSON.parse(
      event.dataTransfer?.getData("json/move-kind") || ""
    );
    const idSource = data.from;
    if (idSource == idTarget) return; // avoid useless moves
    emit("moveKind", props.kinds.concat(data.kind), idSource, idTarget);
  }
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
