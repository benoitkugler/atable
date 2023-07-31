<template>
  <v-card title="Modifier l'ingrédient">
    <v-card-text>
      <v-form>
        <v-row>
          <v-col>
            <PlatSelect v-model="inner.Plat"></PlatSelect>
          </v-col>
        </v-row>
        <v-row>
          <v-col>
            <v-text-field
              variant="outlined"
              density="compact"
              label="Pour tant de personnes"
              type="number"
              v-model.number="inner.Quantity.For_"
            ></v-text-field>
          </v-col>
          <v-col>
            <v-text-field
              variant="outlined"
              density="compact"
              label="Quantité"
              type="number"
              v-model.number="inner.Quantity.Val"
            ></v-text-field>
          </v-col>
          <v-col>
            <UniteSelect v-model="inner.Quantity.Unite"></UniteSelect>
          </v-col>
        </v-row>
      </v-form>
    </v-card-text>
    <v-card-actions>
      <v-spacer></v-spacer>
      <v-btn color="success" @click="emit('update:model-value', inner)"
        >Enregistrer</v-btn
      >
    </v-card-actions>
  </v-card>
</template>

<script lang="ts" setup>
import { MenuIngredient } from "@/logic/api_gen";
import PlatSelect from "@/components/PlatSelect.vue";
import { copy } from "@/logic/controller";
import { ref } from "vue";
import UniteSelect from "@/components/UniteSelect.vue";
import { watch } from "vue";

const props = defineProps<{
  modelValue: MenuIngredient;
}>();

const emit = defineEmits<{
  (event: "update:model-value", v: MenuIngredient): void;
}>();

const inner = ref<MenuIngredient>(copy(props.modelValue));
watch(props, () => (inner.value = copy(props.modelValue)));
</script>
