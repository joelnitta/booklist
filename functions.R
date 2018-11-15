#' get_zotero
#'
#' Download a bibliography from a Zotero group 
#' and convert it to a tibble (tidy dataframe)
#'
#' Groups are located at URLs e.g.,
#' https://www.zotero.org/groups/2220437/mygroup_01/
#'
#' @param groupID Zotero groupID (not group name); 
#' precedes group name in group URL
#' @param api_key API key issued by the group admin
#'
#' @return A tibble

get_zotero <- function (groupID, api_key) {
  RefManageR::ReadZotero(group = (groupID),
                         .params = list(
                           key = (api_key)
                         )) %>%
    as.data.frame %>%
    as_tibble(rownames = "bookID") %>%
    mutate(title = str_remove_all(title, "\\{|\\}")) %>%
    select(bookID, title, author, abstract, year, publisher, edition, isbn)
}

#' load_gs_data
#' 
#' Load a sheet from a google docs table as a dataframe
#' 
#' From https://shiny.rstudio.com/articles/persistent-data-storage.html
#'
#' @param table Name of google docs table
#'
#' @return dataframe

load_gs_data <- function(table) {
  # Grab the Google Sheet
  sheet <- googlesheets::gs_title(table)
  # Read the data
  googlesheets::gs_read_csv(sheet, col_types = cols(.default = "c")) %>%
    # Force all columns to be character
    purrr::map_df(as.character)
}

#' update_gs_cells
#' 
#' Edit cells row-wise in a google sheet for a selected row
#'
#' @param new_vector Character vector of new values to enter into row, one per cell
#' @param key_select Character with value that matches single value in key column
#' @param key_col Name of "key" column used to identify where to edit cells
#' @param gs_data Original data from the google sheet (obtained using load_gs_data)
#' @param gs_object googlesheets object corresponding to gs_data
#'
#' @return a googlesheets object

update_gs_cells <- function (new_vector, key_select, key_col = "bookID", gs_data, gs_object) {
  row_select <- paste0("B", which(gs_data[[key_col]] == key_select) + 1)
  gs_object %>%
    gs_edit_cells(input = new_vector, anchor = row_select, byrow = TRUE, trim = FALSE)
}

format_books <- function (books_df, width_percent_mod, cols_select) {
  widths <- round(str_length(books_df$abstract) * 0.01 * width_percent_mod) + 4
  widths[is.na(widths)] <- 4
  
  books_df %>%
    mutate(
      abstract = 
        map2_chr(abstract, widths, str_trunc)
    ) %>%
    select(cols_select)
}