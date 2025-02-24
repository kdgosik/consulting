import React from 'react';
import Layout from '@theme/Layout';
// import { Jupyter, Cell } from '@datalayer/jupyter-react'
// https://jupyter-ui.datalayer.tech/docs/develop/usage/

export default function MyReactPage() {
  return (
    <Layout>
      <h1>My React page</h1>
      <p>This is a React page</p>
      <h1>Jupyter Code Section</h1>
      {/* <Jupyter lite={true}>
        <Cell
          source={`import sys
            print(f"{sys.platform=}")
            #...`} />
      </Jupyter> */}
    </Layout>
  );
}