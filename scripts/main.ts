insertTemplate("header", "header")
insertTemplate("stub", "stub")
insertTemplate("footer", "footer")
setHead()
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

function setHead() {
    const headTitle = document.querySelector("h1")!.innerHTML
    const title = `${headTitle} - ンソピハワールドWiki`
    const head = document.head;
    head.setAttribute("prefix", "og: https://ogp.me/ns#")
    head.insertAdjacentHTML("beforeend",
        `
        <title>${title}</title>
        <meta property="og:description" content="epikijetesantakalu Ketaが管理人の非公式Wikiです。">
        <meta property="og:title" content="${title}">
        <meta property="og:site_name" content="ンソピハワールドWiki">
        <meta property="og:image" content="https://epikijetesantakalu.github.io/nsopikha-wiki/images/ogp-image.png">
        <meta property="og:image:width" content="1200">
        <meta property="og:image:height" content="630">
        <meta property="og:type" content="website">
        <meta property="og:url" content="https://epikijetesantakalu.github.io/nsopikha-wiki">
        <meta name='theme-color' content='#fafb7c'>`
    );
}