const button = document.getElementById("searchButton")
const searchText: HTMLInputElement = <HTMLInputElement> document.getElementById("search")

button!.addEventListener("click", (e) => {
    console.log(searchText.value)
})