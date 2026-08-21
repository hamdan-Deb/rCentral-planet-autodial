/**
 * Planet ALTIG Lead Scraper & Synchronizer
 * Executes in Browser Developer Console (F12)
 * Extracts Lead ID URLs and Phone Numbers in strict top-to-bottom order.
 */
(async function extractSynchronizedLeads() {
    console.log("Starting Synchronized Sequential Scraper...");

    // Collect all lead links in DOM order
    const rawLinks = Array.from(document.querySelectorAll('a'))
        .filter(a => a.href && (a.href.includes('InboxDetail') || a.href.includes('LeadId')))
        .map(a => a.href);

    const orderedLinks = [];
    const seen = new Set();

    for (const link of rawLinks) {
        if (!seen.has(link)) {
            seen.add(link);
            orderedLinks.push(link);
        }
    }

    let orderedPhoneList = [];
    let orderedLeadMap = [];

    const sleep = ms => new Promise(res => setTimeout(res, ms));
    const BATCH_SIZE = 4;

    for (let i = 0; i < orderedLinks.length; i += BATCH_SIZE) {
        const batch = orderedLinks.slice(i, i + BATCH_SIZE);

        const results = await Promise.all(batch.map(async (url) => {
            try {
                const leadIdMatch = url.match(/LeadId=(\d+)/i);
                const leadId = leadIdMatch ? leadIdMatch[1] : '';

                const res = await fetch(url);
                if (!res.ok) return null;
                const html = await res.text();

                const phoneMatch = html.match(/Ph:\s*\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}|\b\d{10}\b|\(\d{3}\)\s*\d{3}-\d{4}/i);

                if (phoneMatch) {
                    const cleanPhone = phoneMatch[0].replace(/\D/g, '').slice(-10);
                    if (cleanPhone.length === 10) {
                        return {
                            phone: cleanPhone,
                            url: `https://m.planetaltig.com/Lead/InboxDetail?LeadId=${leadId}`
                        };
                    }
                }
            } catch (e) {
                console.error("Error fetching URL:", url);
            }
            return null;
        }));

        results.forEach(item => {
            if (item && item.phone) {
                orderedPhoneList.push(item.phone);
                orderedLeadMap.push({
                    line: orderedLeadMap.length + 1,
                    phone: item.phone,
                    url: item.url
                });
            }
        });

        await sleep(250);
    }

    // Export numbers.txt
    const txtBlob = new Blob([orderedPhoneList.join('\n')], { type: 'text/plain' });
    const a1 = document.createElement('a');
    a1.href = URL.createObjectURL(txtBlob);
    a1.download = 'numbers.txt';
    a1.click();

    // Export lead_map.json
    const jsonBlob = new Blob([JSON.stringify(orderedLeadMap, null, 2)], { type: 'application/json' });
    const a2 = document.createElement('a');
    a2.href = URL.createObjectURL(jsonBlob);
    a2.download = 'lead_map.json';
    a2.click();
    console.log("Both numbers.txt and lead_map.json exported successfully!");
})();
