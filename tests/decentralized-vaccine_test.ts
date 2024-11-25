import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.4/index.ts';
import { assertEquals } from 'https://deno.land/std@0.170.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensure genome submission works correctly",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const researcher = accounts.get('wallet_1')!;
        const block = chain.mineBlock([
            Tx.contractCall('decentralized-vaccine', 'submit-genome-data', [
                types.ascii('genome-1'),
                types.ascii('Malaria Parasite'),
                types.ascii('ATCG GENOME DATA'),
                types.ascii('WHO Research Center'),
                types.list([types.principal(researcher.address)])
            ], researcher.address)
        ]);

        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk().expectBool(true);

        const submission = chain.callReadOnlyFn('decentralized-vaccine', 'get-genome-submission', [
            types.principal(researcher.address),
            types.ascii('genome-1')
        ], researcher.address);

        submission.result.expectSome();
    }
});

Clarinet.test({
    name: "Prevent duplicate genome submissions",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const researcher = accounts.get('wallet_1')!;
        const block = chain.mineBlock([
            Tx.contractCall('decentralized-vaccine', 'submit-genome-data', [
                types.ascii('genome-1'),
                types.ascii('Malaria Parasite'),
                types.ascii('ATCG GENOME DATA'),
                types.ascii('WHO Research Center'),
                types.list([types.principal(researcher.address)])
            ], researcher.address),
            Tx.contractCall('decentralized-vaccine', 'submit-genome-data', [
                types.ascii('genome-1'),
                types.ascii('Malaria Parasite'),
                types.ascii('DUPLICATE DATA'),
                types.ascii('Another Research Center'),
                types.list([types.principal(researcher.address)])
            ], researcher.address)
        ]);

        assertEquals(block.receipts.length, 2);
        block.receipts[0].result.expectOk().expectBool(true);
        block.receipts[1].result.expectErr().expectUint(3); // ERR-DATA-EXISTS
    }
});
