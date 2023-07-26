<template>
  <v-container class="fill-height">
    <v-responsive class="align-center text-center fill-height">
      <v-card>
        <v-row justify="space-between">
          <v-col cols="auto">
            <v-card-title>Séjours</v-card-title>
          </v-col>
          <v-col cols="auto" align-self="center">
            <v-btn class="mr-2">
              <template v-slot:prepend="">
                <v-icon color="green">mdi-plus</v-icon>
              </template>
              Ajouter
            </v-btn>
          </v-col>
        </v-row>
        <v-card-text>
          <v-card>
            <v-row justify="space-between" class="mx-1">
              <v-col align-self="center" cols="6">
                <v-select
                  class="my-2"
                  variant="outlined"
                  label="Séjour actif"
                  hide-details
                  no-data-text="Veuillez ajouter un nouveau séjour..."
                ></v-select>
              </v-col>
              <v-col cols="auto" align-self="center">
                <v-btn flat icon class="mx-1" size="small">
                  <v-icon>mdi-pencil</v-icon>
                </v-btn>
                <v-btn flat icon class="mx-1" size="small">
                  <v-icon color="red">mdi-delete</v-icon>
                </v-btn>
              </v-col>
            </v-row>
            <v-card-text>
             
            </v-card-text>
          </v-card>
        </v-card-text>
      </v-card>
    </v-responsive>
  </v-container>
</template>

<script lang="ts" setup></script>
