import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.4/index.ts';
import { assertEquals, assertNotEquals } from 'https://deno.land/std@0.170.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensure researcher can submit multiple genome entries",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const researcher = accounts.get('wallet_1')!;

        // Submit first genome
        const firstSubmission = chain.mineBlock([
            Tx.contractCall('decentralized-vaccine', 'submit-genome-data', [
                types.ascii('genome-unique-1'),
                types.ascii('Malaria Parasite'),
                types.ascii('DETAILED GENOME SEQUENCE ATCG...'),
                types.ascii('WHO Research Center'),
                types.list([types.principal(researcher.address)])
            ], researcher.address)
        ]);

        // Submit second genome
        const secondSubmission = chain.mineBlock([
            Tx.contractCall('decentralized-vaccine', 'submit-genome-data', [
                types.ascii('genome-unique-2'),
                types.ascii('Dengue Virus'),
                types.ascii('ANOTHER DETAILED GENOME SEQUENCE...'),
                types.ascii('CDC Research Center'),
                types.list([types.principal(researcher.address)])
            ], researcher.address)
        ]);

        // Validate submissions
        firstSubmission.receipts[0].result.expectOk().expectBool(true);
        secondSubmission.receipts[0].result.expectOk().expectBool(true);

        // Retrieve researcher submissions
        const submissions = chain.callReadOnlyFn(
            'decentralized-vaccine', 
            'get-researcher-submissions', 
            [types.principal(researcher.address)], 
            researcher.address
        );

        // Expect submissions to include both genome IDs
        submissions.result.expectSome();
        
        // Additional checks can be added here to verify the exact contents
    }
});

Clarinet.test({
    name: "Prevent duplicate genome submissions",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const researcher = accounts.get('wallet_1')!;

        const duplicateBlock = chain.mineBlock([
            Tx.contractCall('decentralized-vaccine', 'submit-genome-data', [
                types.ascii('genome-unique-3'),
                types.ascii('Malaria Parasite'),
                types.ascii('FIRST SUBMISSION'),
                types.ascii('WHO Research Center'),
                types.list([types.principal(researcher.address)])
            ], researcher.address),
            Tx.contractCall('decentralized-vaccine', 'submit-genome-data', [
                types.ascii('genome-unique-3'),
                types.ascii('Another Parasite'),
                types.ascii('DUPLICATE SUBMISSION'),
                types.ascii('Another Research Center'),
                types.list([types.principal(researcher.address)])
            ], researcher.address)
        ]);

        duplicateBlock.receipts[0].result.expectOk();
        duplicateBlock.receipts[1].result.expectErr();
    }
});
