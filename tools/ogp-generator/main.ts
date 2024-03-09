{
const fs = require("fs")
const list = fs.readFileSync('../../index.json', {encoding: "utf8"});
const jsonList: any[] = JSON.parse(list)

jsonList.forEach(p => {
    let article: string = fs.readFileSync(`../../wiki/${p.html}`, {encoding: "utf8"});
    const title = `${p.title} - ンソピハワールドWiki`

    const head = [
        `<title>${title}</title>`,
        `<meta property="og:description" content="epikijetesantakalu Ketaが管理人の非公式Wikiです。">`,
        `<meta property="og:title" content="${title}">`,
        `<meta property="og:site_name" content="ンソピハワールドWiki">`,
        `<meta property="og:image" content="https://epikijetesantakalu.github.io/nsopikha-wiki/images/ogp-image.png">`,
        `<meta property="og:image:width" content="1200">`,
        `<meta property="og:image:height" content="630">`,
        `<meta property="og:type" content="website">`,
        `<meta property="og:url" content="https://epikijetesantakalu.github.io/nsopikha-wiki">`,
        `<meta name="theme-color" content="#fafb7c">`
    ]

    const check = [
        /<title>.*?<\/title>/,
        /<meta property="og:description" content=".*?">/,
        /<meta property="og:title" content=".*?">/,
        /<meta property="og:site_name" content=".*?">/,
        /<meta property="og:image" content=".*?">/,
        /<meta property="og:image:width" content=".*?">/,
        /<meta property="og:image:height" content=".*?">/,
        /<meta property="og:type" content=".*?">/,
        /<meta property="og:url" content=".*?">/,
        /<meta name="theme-color" content=".*?">/
    ]

    head.forEach((h, idx) => {
        if (article.match(check[idx])) {
            article = article.replace(check[idx], h)
            console.log(`replaced tag: ${p.html}`)
        } else {
            article = article.replace(/<\/head>/, ` ${h}
    <\/head>`)
            console.log(`added tag: ${p.html}`)
        }
    })
    
    fs.writeFileSync(`../../wiki/${p.html}`, article)
})
}