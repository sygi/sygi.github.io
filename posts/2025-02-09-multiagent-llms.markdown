---
title: 'Small Multiagent Vision for Large Language Models'
---

Multiagent algorithms are not in the mainstream focus nowadays, in particular, LLM development rarely incorporates them.

This post explains why I think the characteristics of LLMs make them ideal candidates for multiagent algorithms.

## What makes an algorithm multiagent?

This post focuses on RL algorithms (i.e. agents acting in an environment optimizing some reward). 

Multi-agent RL (MARL) can be seen as a syntactic sugar: we can always model the behavior of other agents as part of the environment. It is sometimes a useful mental model for designing learning systems.

Multi-agent algorithms fall into two categories[^1]:

1. Analyzing what properties emerge in a system where there are multiple independent agents with particular behaviors, eg. analyzing versions of Tragedy of the commons
2. Using the diversity of the agents' behavior to create a curriculum to faster/better train agent(s) toward their goal, eg. [Starcraft league](https://www.nature.com/articles/s41586-019-1724-z.epdf?author_access_token=lZH3nqPYtWJXfDA10W0CNNRgN0jAjWel9jnR3ZoTv0PSZcPzJFGNAZhOlk4deBCKzKm70KfinloafEF1bCCXL6IIHHgKaDkaTkBcTEv7aT-wqDoG1VeO9-wO3GEoAMF9bAOt7mJ0RWQnRVMbyfgH9A%3D%3D)

In this write-up, I'm going to use the second definition.

[^1]: The [Wikipedia page](https://en.wikipedia.org/wiki/Multi-agent_reinforcement_learning) explain the related concepts in more detail.

## General strategy

If MARL is a _method_ for improving agents' performance, how we apply it to an RL problem? It is the easiest when the RL problem is expressed as a game between players.

In a typical RL approach, an agent will play against the same environment, collecting the rewards and updating its behavior based on them. In a sense, even if there is a fixed opponent (eg. a bot against which to play in chess), from the perspective of the learning agent, the environment looks like they are playing a single-player game.

The multi-agent method tells us to vary the opponents in the game according to the current needs of the player: there may be a particular weakness the current agent has that can be exploited (and, in effect, trained against), or a particular collaborator to adapt to. This helps the agent to learn faster than if it were to explore various strategies with a limited set of co-players.

The other (usually fixed) players to be put in the environment may be hard-coded (in which case their utility is limited, as there is only as much you can learn from a single co-player), or generated through an automated process (eg. old versions of yourself in fictitious self-play [^4]).

[^4]: https://proceedings.mlr.press/v37/heinrich15.pdf

<details>
<summary>
    On RL & math of the gradient estimator
</summary>
    
In RL, as opposed to supervised learning, the agent controls what data it trains on. While, in theory, making parameter updates using an unbiased estimator of the gradient of the objective:

$$
\theta \leftarrow \theta + \alpha \sum_{t=0}^{T} \nabla_{\theta} \log \pi_{\theta}(a_t | s_t) R_t
$$

will lead to convergence to the (locally) optimal policy[^2], the rate of convergence will vary widely depending on the variance of the estimator.

[^2]: as long as the original objective includes the discount terms, see [reference](https://arxiv.org/pdf/1906.07073)
    
One mechanism to decrease the variance, explored in the context of multiagent algorithms, is to consistently put the agent in situations with varying rewards[^3], to teach it to distinguish what to do from what to avoid.

To understand how increasing the variance of the rewards helps agents to learn, consider the following mind experiment:
Imagine that an agent is placed in a room with two doors: red and blue. If it goes through the red door, it gets the reward of 1 and the episode terminates. If it goes through the blue door, it gets to a new room, where it is playing a proper game, and, depending on its score, it gets 0 or 100.
    
Now, if the agent consistently chooses the red (boring) door 99% of the time, its proper learning experience is limited to only 1% of the time and is affected by the noise from the uninteresting episodes.
    
[^3]: See e.g. Value Correction Hypothesis in [Prioritized Level Replay](https://proceedings.mlr.press/v139/jiang21b/jiang21b.pdf)
</details>

## When to use MARL?

Many of the RL problems can be solved without resolving to multiagent methods using standard techniques like policy gradient, planning in model-based RL, trust-region methods like PPO, and others.

I believe there are two properties of a problem that make it particularly amenable to MARL:

1. The environment being collaborative (as opposed to competitive), and
2. a large non-transitive dimension amongst average/typical policies

### Collaboration
In a collaborative environment, a positive/high reward for one player correlates with a positive reward for another player.

In collaborative environments, the players often need to coordinate their actions and adapt to each other strategies: if one player makes a bad move, the other has to compensate instead of penalizing the first player. An agent needs to learn to cooperate with a wide range of policies, instead of finding the best action assuming optimal play from the opponent.

As MARL involves agent training with a range of co-players, handling a wide diversity of collaborators may become easier.

### Non-transitivity
Let's define non-transitivity as the presence of a cycle long of strategies $\pi_0, \ldots, \pi_{n-1}$ such that $\pi_i$ beats $\pi_{(i+1)\mod n}$ for each $i$.

For the training of an RL model to progress, it needs to see examples of things it does right and ones it does badly. As the non-transitive cycle is long, it is difficult to provide the right set of challenges to a policy $\pi$ without additional information about it. We would like to ask $\pi$ to play with its neighbors in the cycle to learn from them, but we don't, a priori, have a way to find them.

In this situation it feels more natural to learn as a population, keeping up-to-date win-rate statistics to be able to provide the right opponents at the right time.

Note: one can argue that interesting games of skill have large non-transitive components ([ref: spinning tops paper](https://arxiv.org/pdf/2004.09468)).

## Large Language Models

What does it have to do with LLMs? One can model LLMs answering people's questions as solving an RL environment with two players: the human (H) who asks the question and the model (LLM) who answers it. The reward the model receives correlates with how much a human likes the answer.[^5]

[^5]: for a comprehensive intro on modeling LLM chat as an RL process, take a look at [this post](https://huggingface.co/blog/rlhf)

This RL problem has the properties suggesting MARL techniques will be successful:

1. The game is collaborative: the goal of H is to phrase the question in such a way as to receive the response from LLM it likes (high reward for LLM = high reward for H).
2. The problem is highly non-transitive:
    a. there is no common agreement of what an "answer a human likes" looks like: within humans, there is non-transitivity in preferences where one human may like A more than B whereas another prefers B from A.
    b. even a single human isn't always consistent, has a non-zero variance in establishing preference, and might genuinely have non-transitive preferences. [^6]
3. Due to the vast range of topics (should they be called subenvironments?) that the problem consists of, it is easy to construct a varying pool of agents, both on H and LLM sides:
    a. for H, one may consider:
       - humans with varying expertise/interests
       - different LLMs posing as such humans
       - writing a program generating a large set of questions from a well-defined pool
       - using a program like a compiler or a spell-checker to evaluate the quality of an answer
       - combining any of the above, splitting the responsibility for asking a question and evaluating an answer to separate entities
    b. for LLM, it seems natural to:
       - finetune LLMs on data relating to different topics
       - include some data (evaluation's test split, safety alignment data) in the training or not
       - allow to use tools or not
       - adjust the LLM with system prompts
       - align the LLM to follow a grammar during inference[^7]
    
[^6]: this sounds like a great place for a reference, but I don't have one (let me know if you do!)
[^7]: see [constrained decoding](https://www.aidancooper.co.uk/constrained-decoding/)


### Somewhat? concrete proposal

There are millions of ways of implementing the multiagent concept in LLMs.

One, conceptually simple, I would try time allowing, follows this:
1. Let's fine-tune (potentially with LoRA) an agent on a number of different datasets from different domains: one on math, one on programming, one on biology, etc.
2. Keep using the "experts" in their respective domains to teach the other ("student") agents by:
    - taking a problem from the expert domain
    - generate the chain of thought/explanation of a correct solution
    - use it as a few-shot prompt for the student
    - evaluate the student on a similar problem using an independent expert/ground truth
    - reward the student based on the correctness of the answer and the teacher on the improvement the few-shot example gave
3. Keep training the models on the reward / useful examples and see them improve as a population.

This is not a sophisticated project, but it can help assess the promise of the idea compared to just training the agents on all the available data.

## Outro

Multiagent algorithms have been there long before LLMs and, while still being present in research (eg. see a bit outdated [survey](https://arxiv.org/pdf/2402.01680)), they didn't yet enter mainstream[^8].

I expect and hope to see more of them in the coming months and years!

[^8]: or maybe it only feels that way due to big labs publishing less these days?
