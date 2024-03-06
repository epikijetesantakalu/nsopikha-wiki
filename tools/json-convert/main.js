"use strict";
const yaml = require("js-yaml");
const fs = require("fs");
const yamlText = fs.readFileSync('index.yml', { encoding: "utf8" });
const body = yaml.load(yamlText);
const text = JSON.stringify(body, null, 2); // JSONに変換
fs.writeFile('index.json', text, 'utf8', (err) => {
    if (err !== null) {
        // エラー処理
        return false;
    }
});
