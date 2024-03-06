"use strict";
const button = document.getElementById("searchButton");
const searchText = document.getElementById("search");
button.addEventListener("click", (e) => {
    console.log(searchText.value);
});
