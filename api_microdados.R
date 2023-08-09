pacman::p_load(tidyverse, # caixa de ferramentas 
               bigrquery, # Para acessar o query do google
               plotly
               
)

# base de dados 

conexao <- dbConnect( 
  bigquery(),
  project = "basedosdados",
  dataset = "br_me_rais" ,
  billing = "black-overview-334521"
  #dataset = "br_me_caged",
  #dataset = "br_me_cpnj"
)

tbl(conexao,"microdados_vinculos") %>% 
  select( everything() ) %>% 
  filter( 
    ano >= 2013 ,sigla_uf == "CE"
  )  %>%  head(5000)


# baixar todos os dados
microdados_tbl <-  tbl(conexao,"microdados_vinculos") |> 
  select( everything()) |> 
  collect() 

tbl(conexao, "microdados_vinculos") |> collect()
