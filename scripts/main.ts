insertTemplate("header", "header")
insertTemplate("stub", "stub")
insertTemplate("footer", "footer")
document.body.style.display = 'block' //読み込みが終わったら表示

window.onload = () => {
    const searchButton = document.getElementById("searchButton")
    const searchText: HTMLInputElement = <HTMLInputElement> document.getElementById("search")

    searchButton!.addEventListener("click", (e) => {
        window.location.assign(`/nsopikha-wiki/specials/search.html?text=${searchText.value}`);
    })
}

function insertTemplate (file: string, className: string) {
    const req = new XMLHttpRequest()

    req.open("GET", `/nsopikha-wiki/layouts/${file}.html`, true)

    req.onreadystatechange = () => {
        if (req.readyState === 4 && req.status === 200) {
            const HTML = req.responseText;
            const elements = document.getElementsByClassName(className)

            Array.from(elements).forEach((e) => {
                e.insertAdjacentHTML("afterbegin", HTML);
            })
        }
    }

    req.send()
}