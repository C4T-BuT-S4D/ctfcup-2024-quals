const process = require('node:process');

const puppeteer = require("puppeteer");

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

const TIMEOUT = process.env.TIMEOUT || 300 * 1000;
const SLEEP_TIME = process.env.SLEEP_TIME || 180 * 1000;
const CHAT_URL = process.env.CHAT_URL || 'http://localhost:8080/';

const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD;

async function visit() {
    const params = {
        browser: 'chrome',
        args: [
            '--no-sandbox',
            '--disable-gpu',
            '--disable-extensions',
            '--js-flags=--jitless',
        ],
        headless: true,
    };

    const browser = await puppeteer.launch(params);
    const context = await browser.createBrowserContext();

    const pid = browser.process().pid;

    const shutdown = async () => {
        await context.close();
        await browser.close();

        try {
            process.kill(pid, 'SIGKILL');
        } catch(_) { }

        process.exit(0);
    };

    const page1 = await context.newPage();
    await page1.setViewport({
      width: 1920,
      height: 1080,
      deviceScaleFactor: 1,
      isMobile: false
    });

    await page1.goto(`${CHAT_URL}`);
    const inputs = await page1.$$('input');
    await inputs[0].type('admin');
    await inputs[1].type(ADMIN_PASSWORD);
    const button = await page1.$('button');
    await button.click();

    await sleep(SLEEP_TIME);
    await shutdown();
}

async function main() {
    await visit();

    await sleep(TIMEOUT);
}

main();
