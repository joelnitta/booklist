
booklist
========

The purpose of this **R** package is to facilitate maintenance of a database of books, such as those used for courses within a university department.

Our scenario is that several people need to enter data for purchasing books (ISBN, title, author, etc), and also keep track of who purchased which book when, and who has the book in their possession (who has "checked-out" the book).

There are obviously many more advanced was to construct such a database, but here we will use make use of two pre-existing solutions with some convenient features: [Zotero](https://www.zotero.org/) and [Google Sheets](https://www.google.com/sheets/about/).

**Zotero** is a bibliography manager. We will leverage its "Groups" feature, which allows for collaborative editing of bibliographies by members of a group. This way, any of the users who need to purchase books can edit a single list. Another useful feature of Zotero is its [browser plugin](https://www.zotero.org/download/). This can detect bibliographic information (such as on an Amazon product page), and import it directly to the database with a single click. This makes it extremely easy and error-free to import book titles and ISBNs for purchasing.

**Google Sheets** is a cloud-based spreadsheet editor, so it is convenient for multiple users to edit the same document. We will also make use of its data-validation and versioning features.

`booklist` connects Zotero and Google Sheets so book data can be easily entered and maintained.

Installation
------------

Please install the package from github:

``` r
install.packages("devtools")
devtools::install_github("joelnitta/booklist")
```

Usage
-----

First [set up Zotero as described below](#setting-up-zotero). Take note of the Zotero API key and groupID.

Next, initialize the google sheet to manage the booklist using your google drive account. **You should only have to do this once**.

`googlesheets` will also take care of authentication the first time.

``` r
library(booklist)

initiate_booklist(groupID = "YOUR_ZOTERO_GROUPID",
                  api_key = "YOUR_ZOTERO_API_KEY",
                  sheet_name = "example_booklist")
```

You should now have a google sheet called "example\_booklist" in the root folder of your Google Drive, populated with data from the Zotero bibliography.

Optionally [set up data validation](#data-validation) to prevent craziness during data entry.

Edit purchasing and check-out data as needed in Google Sheets.

After adding more books with Zotero, sync the two databases:

``` r
update_booklist(groupID = "YOUR_ZOTERO_GROUPID",
                  api_key = "YOUR_ZOTERO_API_KEY",
                  sheet_name = "example_booklist")
```

Setting up Zotero
-----------------

First, [create an account](https://www.zotero.org/user/register) if you don't have one, then [log in](https://www.zotero.org/user/login/).

### Install the Zotero desktop app

Go to the [Zotero downloads page](https://www.zotero.org/download/) and install the desktop app for your OS.

### Install the Zotero browser plugin

Go to the [Zotero downloads page](https://www.zotero.org/download/). Install the "Zotero Connector" plugin for your browser. As of writing, plugins were available for Chrome, Firefox, and Safari.

### Create a new private group

-   Open the "Groups" tab
-   Click "Create a New Group"
-   Choose a name and select "Choose Private Membership", then save settings

View your Zotero group database by clicking the name of the group under "Home &gt; Groups &gt; (name of group)" in the set of links just below the tabs at the top of the page.

Take note of the 7-digit number in the URL for your group just before the group name.

This is the `groupID` number that will be used by the `booklist` code.

### Set up an API key to access the group database

Go to [this page](https://www.zotero.org/settings/keys/new) to create a new private key.

-   Enter a description for the key
-   Check the "Allow library access" box under **Personal Library**
-   Select "None" for "All Groups" under **Default Group Permissions**
-   Check the "Per Group Permissions" box
-   After checking the "Per Group Permissions" box, select "Read/Write" under the name of the private group you created above (if there are other groups, select "none" for their permissions for this key).
-   Press "Save Key"

In the next window that opens, a long series of numbers and characters will appear under "Key Created". **COPY** this somewhere secure because you won't have access to it again after the window closes.

This is the `api_key` that will be used by the `booklist` code.

### Add books to the database

To use the browser plugin, simply go to your favorite book on Amazon and click the "Save to Zotero" button. Make sure to select the name of the private group, not just your personal library.

Data Validation
---------------

Open the google sheet in your browser and make the following changes:

### Locale

The locale determines default time and date format.

File -&gt; Spreadsheet settings... -&gt; Set Locale to Japan (or your preference)

### Date validation

This makes sure the input is some kind of date, but it doesn't check the date format. Please use YYYY-MM-DD format. If you click the box and use the drop-down calendar, it will be YYYY-MM-DD (at least for Japan).

Data -&gt; Data validation... -&gt;

-   Cell range: Sheet1!H2:H
-   Criteria: Date is valid date
-   On invalid data: Reject input
-   Check the "Appearance: show validation help text" box

Data -&gt; Data validation... -&gt;

-   Cell range: Sheet1!J2:J
-   Criteria: Date is valid date
-   On invalid data: Reject input
-   Check the "Appearance: show validation help text" box

### Checkbox validation

This makes sure the input for the "purchased" and "checked\_out" columns are checkboxes.

Data -&gt; Data validation... -&gt;

-   Cell range: Sheet1!G2:G
-   Criteria: Checkbox
-   On invalid data: Reject input

Data -&gt; Data validation... -&gt;

-   Cell range: Sheet1!I2:I
-   Criteria: Checkbox
-   On invalid data: Reject input

### Name validation

This makes sure the same names for people who purchase and checkout books are used consistently.

Data -&gt; Data validation... -&gt;

-   Cell range: Sheet1!K2:K
-   Criteria: List of items. In the list, input the name of each user separated by a comma. (e.g., Joel, Marie).
-   Check the "Show dropdown list in cell" box
-   On invalid data: Reject input

### Protected Data

The data imported from the Zotero bibliography should not be edited in the google sheet.

Data -&gt; Protected sheets and ranges -&gt; Add a sheet or range -&gt;

-   Description: Zotero
-   Range: Sheet1!A:F
-   Set permissions -&gt; "Show a warning when editing this range"
