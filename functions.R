#' Create a google sheet with data imported from Zotero
#'
#' The google sheet will be created in the user's google drive root folder.
#'
#' @param sheet_name Name to use for the google sheet
#' @param groupID ID number of Zotero group with bibliography
#' @param api_key API key needed to access Zotero group
#'
#' @return A \code{\link[googlesheet]{googlesheets}} object; a google sheet 
#' will be created using data from Zotero, and new columns for purchase and 
#' loan status will be added.
#' @export
initiate_booklist <- function (sheet_name, groupID, api_key) {
  
  # Check if any files in drive root folder are already present with same name
  # as sheet_name
  already_in_drive <- googledrive::drive_find(
    pattern = sheet_name,
    q = "'root' in parents") %>%
    dplyr::pull(name)
  
  assertthat::assert_that(
    !any(sheet_name %in% already_in_drive),
    msg = "A sheet with the same name already exists in your google drive root folder")
  
  get_zotero(groupID = groupID, api_key = api_key) %>%
    dplyr::mutate(purchased = "",
           date_purchased = "",
           checked_out = "",
           date_checked_out = "",
           who_checked_out = "") %>%
    googlesheets::gs_new(sheet_name, input = ., trim = TRUE)
}

#' Import data from Zotero
#'
#' Download a bibliography from a Zotero group 
#' and convert it to a tibble (tidy dataframe).
#'
#' To find the groupID of your private Zotero group, look at its URL. 
#' The groupID is the part just before the group name. For example, 
#' the groupID of 
#' 
#' https://www.zotero.org/groups/2220437/mygroup_01/
#'
#' is 2220437.
#'
#' @param groupID Zotero groupID (not group name); 
#' precedes group name in group URL
#' @param api_key API key issued by the group admin
#'
#' @return A tibble
#' @export
get_zotero <- function (groupID, api_key) {
  RefManageR::ReadZotero(group = (groupID),
                         .params = list(
                           key = (api_key)
                         )) %>%
    as.data.frame %>%
    dplyr::as_tibble() %>%
    dplyr::mutate_all(~str_remove_all(., "\\{|\\}")) %>%
    dplyr::select(title, author, year, publisher, edition, isbn)
}

#' Load a google sheet as a dataframe
#' 
#' From https://shiny.rstudio.com/articles/persistent-data-storage.html
#'
#' @param table Name of google sheet
#'
#' @return dataframe
#' @export
load_gs_data <- function(table) {
  # Grab the Google Sheet
  sheet <- googlesheets::gs_title(table)
  # Read the data
  googlesheets::gs_read_csv(sheet, col_types = cols(.default = "c")) %>%
    # Force all columns to be character
    purrr::map_df(as.character)
}


#' Verify that all ISBN numbers are unique
#'
#' @param data Dataframe including at least one column called "isbn"
#' @param data_source Either "Google" or "Zotero"
#'
#' @return TRUE if there are no duplicate ISBN numbers or an error stating
#' which ISBN numbers are duplicates.
check_isbn <- function(data, data_source = c("Google", "Zotero")) {
  dup_isbn <-
    data %>%
    dplyr::count(isbn) %>%
    dplyr::filter(n > 1) %>%
    dplyr::pull(isbn) %>%
    paste(collapse = ", ")
  
  assertthat::assert_that(
    dup_isbn == "",
    msg = glue::glue("Duplicate ISBNs detected in {data_source} data: {dup_isbn}. 
                     Please remove these before updating.")
    )
}


#' Synchronize a Zotero bibliography and a Google Sheet
#' 
#' It is assumed that the google sheet is located in the root folder of the
#' user's Google Drive.
#'
#' @param groupID ID number of Zotero group with bibliography
#' @param api_key API key needed to access Zotero group
#' @param sheet_name Name of the google sheet
#'
#' @return NULL; the google sheet should be updated with new book entries from Zotero, if any.
#' @export
update_booklist <- function (groupID, api_key, sheet_name) {
  
  # Read in current bibliographic data from Zotero
  zotero_data <- get_zotero(groupID = groupID, 
                            api_key = api_key)
  
  # Make sure ISBNs are unique in Zotero data
  check_isbn(zotero_data, "Zotero")
  
  # Get book status data (whether purchased or checked out) from googlesheets 
  book_status <- load_gs_data("booklist") %>%
    dplyr::select(isbn, contains("purchased"), contains("checked_out"))
  
  # Make sure ISBNs are unique in google data
  check_isbn(book_status, "Google")
  
  # Merge Zotero data with book status and update google sheet
  book_update <-
    dplyr::full_join(zotero_data, book_status) %>%
    dplyr::mutate_all(~ifelse(is.na(.), "", .))
  
  # Update googlesheet with new data
  googlesheets::gs_title(sheet_name) %>%
    googlesheets::gs_edit_cells(input = book_update)
  
}
