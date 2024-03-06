const urlString = window.location.href
const url = new URL(urlString)
const urlParams = url.searchParams.get("text")
const searchText = urlParams? urlParams: ""

const display = document.getElementById("searchDisplay")

const xhr = new XMLHttpRequest()
xhr.open('GET', "/nsopikha-wiki/index.json")

xhr.onload = () => {
    const pageData = JSON.parse(xhr.response)
    
    const filtered = pageData.filter((p: any) => p.title.includes(searchText))

    display!.innerHTML = makeList(filtered)
}

xhr.send();

function makeList(data: any[]) {
    const pages = 
        data.reduce((prev, p) => {
            return prev + `\n<li><a href="/nsopikha-wiki/pages/${p.html}">${p.title}</a></li>`
        }, "")
    return `<ol>${pages}\n</ol>`
}