"use strict";
{
    const xhr = new XMLHttpRequest();
    xhr.open('GET', "/nsopikha-wiki/index.json");
    xhr.onload = () => {
        const pageData = JSON.parse(xhr.response);
        const epikuElem = document.getElementById("epikuContent");
        const numberElem = document.getElementById("articleCount");
        numberElem.innerHTML = pageData.length;
        const epikuID = Math.floor(Math.random() * pageData.length);
        const epiku = pageData[epikuID];
        const pageXhr = new XMLHttpRequest();
        pageXhr.open('GET', `/nsopikha-wiki/wiki/${epiku.html}`);
        pageXhr.onload = () => {
            const epikuContent = pageXhr.response
                .replace(/<script[^]*/g, "") //スクリプト部分をカット
                .replace(/<[^]*?>/g, "") //タグをカット
                .replace(/\n/g, "") //改行削除
                .replace(/[\s\t]+/g, " ") //複数スペース・タブをまとめる
                .slice(0, 100); //100文字制限
            console.log(epikuContent);
            epikuElem.innerHTML =
                `
            <span class="epikuTitle">
                <a href="/nsopikha-wiki/wiki/${epiku.html}">
                    ${epiku.title}
                </a>
            </span>
            <div class="epikuText">
                ${epikuContent}…
            </div>`;
        };
        pageXhr.send();
    };
    xhr.send();
}
