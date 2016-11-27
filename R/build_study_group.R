#' Builder Class for Drug Class Study Groups
#' @import dplyr
#' @importFrom plyr mapvalues
#' @import stringr
#' @import tidyr
#' @import readr
#' @import purrr
#' @import lubridate
#' @importFrom Kmisc kLoad

build_study_group <- R6::R6Class(
  'build_study_group',
  inherit = study_pop_library,
  
  public = list(
    year = NULL,
    partd_docs = data_frame(),
    openpay_docs = data_frame(),
    study_population_docs = data_frame(),
    final_study_group = data_frame(), 
    study_pop = Kmisc::kLoad('data/study_pop.rData'),
    
    initialize = function(yr = '2014') {
      self$year <- yr
    },
    
    read_processed_tables = function() {
      self$partd_docs <- Kmisc::kLoad(self$processed_file_dir, self$year, 
                                          '/partd_docs.rData')
      self$openpay_docs <- Kmisc::kLoad(self$processed_file_dir, self$year,
                                        '/open_payments_docs.rData') %>% 
        mutate(doc_last_name = toupper(doc_last_name),
               doc_first_name = toupper(doc_first_name),
               doc_city = toupper(doc_city),
               doc_state = toupper(doc_state))
    },
    
    merge_processed_data = function() {
      self$study_population_docs <- self$partd_docs %>% 
        left_join(self$openpay_docs, by = c('doc_first_name', 'doc_last_name', 'doc_city', 'doc_state'))
    },

    filter_processed_data = function() {
      # filtering duplicate Open Payment Doc matching criteria
      self$study_population_docs <- self$study_population_docs %>% 
        group_by(NPI) %>% 
        mutate(dup_count = n()) %>% 
        filter(dup_count == 1) %>% 
        ungroup()
      self$study_pop$unq_match_crit_op_docs <- nrow(self$study_population_docs)
        
      # filtering medical school graduation
      self$study_population_docs <- self$study_population_docs %>% 
        filter(doc_grad_year >= self$exclusion_criteria$grad_year_limits[1], 
               doc_grad_year <= self$exclusion_criteria$grad_year_limits[2])
      self$study_pop$med_grad_exclude_docs <- nrow(self$study_population_docs)
      self$study_pop$final_study_docs <- nrow(self$study_population_docs)
    },
  
    save_study_population = function() {
      study_pop <- self$study_pop
      save(study_pop, file = 'data/study_pop.rData')
      final_study_population <- self$study_population_docs
      save(final_study_population, file = paste0(self$processed_file_dir, self$year, 
           '/final_study_population.rData'))
    },
    
    build_tables = function() {
      self$read_processed_tables()
      self$merge_processed_data()
      self$filter_processed_data()
      self$save_study_population()
    }
      
  )
)
