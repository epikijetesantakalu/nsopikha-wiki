window.onload = () => {
    insertTemplate("header", "header")
    insertTemplate("stub", "stub")
    insertTemplate("footer", "footer")
    setTitle()
    document.body.style.display = 'block' //読み込みが終わったら表示
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

function setTitle () {
    const headTitle = document.querySelector("h1")!.innerHTML
    const title = `${headTitle} - ンソピハワールドWiki`
    const head = document.head;
    head.insertAdjacentHTML("beforeend", `<title>${title}</title>`);
}