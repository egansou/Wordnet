WordNet is a semantic lexicon for the English language that is used extensively by computational linguists and cognitive scientists. WordNet groups words into sets of synonyms called *synsets* and describes semantic relationships between them. Relevant to this project is the *is-a* relationship, which connects a *hyponym* (more specific synset) to a *hypernym* (more general synset). For example, a plant organ is a hypernym to plant root and plant root is a hypernym to carrot.

- Ruby Files
  - **graph.rb**: A simple graph implementation for use in your WordNet. 
  - **wordnet.rb**: Contains a skeleton implementation of the three classes.
  - **interactive.rb**: A frontend that utilizes the methods you have written to interface with WordNet. 

In order to perform operations on WordNet, we will construct our own representation of hypernym relationships using the provided graph implementation. Each vertex `v` is a non-negative integer representing a synset id, and each directed edge `v->w` represents `w` as a hypernym of `v`. The graph is directed and acyclic (DAG), though not necessarily a tree since each synset can have several hypernyms. A small subset of the WordNet graph is illustrated below.  
![alt text](https://github.com/egansou/Wordnet/blob/master/image-resources/sample-graph.png)

