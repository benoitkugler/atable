<template>
  <v-snackbar app v-model="show" :timeout="4000" color="red">
    <b>{{ props.error.Kind }}</b>
    <div v-html="props.error.HTML"></div>
  </v-snackbar>
</template>

<script lang="ts" setup>
import { Error } from "@/logic/controller";
import { watch } from "vue";
import { ref } from "vue";

const props = defineProps<{
  error: Error;
}>();

const show = ref(!!props.error.Kind.length);

watch(props, () => {
  show.value = !!props.error.Kind.length;
});
</script>
