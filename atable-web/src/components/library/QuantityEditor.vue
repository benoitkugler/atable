<template>
  <v-card title="Modifier la quantié">
    <v-card-text>
      <v-form>
        <v-row>
          <v-col>
            <v-text-field
              type="number"
              v-model.number="inner.Val"
              label="Quantité"
              variant="outlined"
              density="compact"
              autofocus
              @focus="$event.target.select()"
              hide-details
            >
            </v-text-field>
          </v-col>
          <v-col>
            <UniteSelect v-model="inner.Unite"></UniteSelect>
          </v-col>
        </v-row>
        <v-row>
          <v-col>
            <v-text-field
              type="number"
              v-model.number="inner.For"
              label="Pour"
              variant="outlined"
              density="compact"
              hint="Les quantités sont relatives à ce nombre de personnes."
              persistent-hint
            >
            </v-text-field>
          </v-col>
        </v-row>
      </v-form>
    </v-card-text>
    <v-card-actions>
      <v-spacer></v-spacer>
      <v-btn color="success" @click="emit('update', inner)">Enregistrer</v-btn>
    </v-card-actions>
  </v-card>
</template>

<script setup lang="ts">
import type { QuantityR } from "@/logic/api_gen";
import { copy } from "@/logic/controller";
import { ref } from "vue";
import UniteSelect from "../UniteSelect.vue";

const props = defineProps<{
  quantity: QuantityR;
}>();

const emit = defineEmits<{
  (e: "update", q: QuantityR): void;
}>();

const inner = ref(copy(props.quantity));
</script>
