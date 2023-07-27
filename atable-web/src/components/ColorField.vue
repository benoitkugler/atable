<template>
  <v-text-field
    variant="outlined"
    density="compact"
    label="Couleur"
    :model-value="props.modelValue"
    @update:model-value="(v) => emit('update:model-value', v)"
    hide-details
  >
    <template v-slot:append>
      <v-menu
        v-model="showColorPicker"
        top
        nudge-bottom="105"
        nudge-left="16"
        :close-on-content-click="false"
      >
        <template v-slot:activator="{ isActive, props: innerProps }">
          <v-btn
            title="Modifier la couleur"
            v-on="{ isActive }"
            v-bind="innerProps"
            :color="props.modelValue"
            block
            width="100px"
          >
          </v-btn>
        </template>
        <v-card>
          <v-card-text class="pa-0">
            <v-color-picker
              :model-value="props.modelValue"
              @update:model-value="(v) => emit('update:model-value', v)"
              flat
              mode="hexa"
              hide-inputs
            />
          </v-card-text>
        </v-card>
      </v-menu>
    </template>
  </v-text-field>
</template>

<script lang="ts" setup>
import { ref } from "vue";

const props = defineProps<{
  modelValue: string;
}>();

const emit = defineEmits<{
  (event: "update:model-value", v: string): void;
}>();

const showColorPicker = ref(false);
</script>
