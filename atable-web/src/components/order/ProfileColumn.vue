<template>
  <v-card>
    <v-row no-gutters>
      <v-col
        align-self="center"
        :cols="toEdit == null ? 'auto' : '11'"
        class="mt-2 px-2"
        @click="props.supplier.Id < 0 ? null : (toEdit = props.supplier.Name)"
      >
        <div v-if="toEdit == null" class="text-subtitle-2 title px-1">
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
      <v-col cols="auto" align-self="center" v-if="props.supplier.Id >= 0">
        <v-btn icon size="x-small" class="ma-2" @click="emit('delete')">
          <v-icon color="red">mdi-delete</v-icon>
        </v-btn>
      </v-col>
    </v-row>
    <!-- <template v-slot:append>
        <v-btn
          >Ajouter un fournisseur
          <template v-slot:prepend>
            <v-icon color="success">mdi-plus</v-icon>
          </template>
        </v-btn>
      </template> -->
    <v-card-text class="py-1 pr-3 pl-1">
      <v-list
        style="max-height: 79vh"
        class="overflow-y-auto"
        density="compact"
      >
        <v-list-item
          v-for="(ingredient, index) in props.ingredients"
          :key="index"
          :subtitle="ingredient.Name"
        ></v-list-item>
      </v-list>
    </v-card-text>
  </v-card>
</template>

<script lang="ts" setup>
import { Ingredient, Supplier } from "@/logic/api_gen";
import { ref } from "vue";

const props = defineProps<{
  supplier: Supplier;
  ingredients: Ingredient[];
}>();

const emit = defineEmits<{
  (e: "update", name: string): void;
  (e: "delete"): void;
}>();

const toEdit = ref<string | null>(null);
function onBlur() {
  const s = toEdit.value || "";
  toEdit.value = null;
  if (s == props.supplier.Name) return;
  emit("update", s);
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
