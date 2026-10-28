{%- macro concat_columns(columns, delim = ', ') %}
    {%- for column in columns -%}
        {{ column }} {% if not loop.last %} || '{{ delim }}' || {% endif%}
    {%- endfor -%}
{% endmacro %}

{% macro drop_old_relations(dryrun=False) %}

{# находим все можели, seed, snapshot проекта dbt #}

{% set current_models = [] %}

{% for node in graph.nodes.values() | selectattr('resource_type', 'in', ['model', 'snapshot', 'seed']) %}
    {% do current_models.append(node.name) %}
{% endfor %}

{# формирование скрипта удаления всез таблиц и вьюх, которым не соответствует ни одна модель, сид и снэпшот #}

{% set cleanup_query %}
with MODELS_TO_DROP as (
    select
        case
            when TABLE_TYPE = 'BASE TABLE' then 'TABLE'
            when TABLE_TYPE = 'VIEW' then 'VIEW'
        end as RELATION_TYPE,
        CONCAT_WS('.', TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME) as RELATION_NAME
    from
        {{ target.database }}.INFORMATION_SCHEMA.TABLES
    where
        TABLE_SCHEMA = '{{ target.schema }}'
        and upper(table_name) not in (
            {%- for model in current_models -%}
                '{{ model.upper() }}'
                {%- if not loop.last -%}
                    ,
                {%- endif %}
            {%- endfor -%}
        )
    )
select
    'DROP ' || RELATION_TYPE || ' ' || RELATION_NAME || ';' as DROP_COMMAND
from
    MODELS_TO_DROP;
{% endset %}

{% do log(cleanup_query) %}

{% set drop_commands = run_query(cleanup_query).columns[0].values() %}

{% do log(drop_commands, True) %}

{# удаление лишних таблиц и вьюх / вывод скрипта удаления #}

{% if drop_commands %}
    {% if dryrun | as_bool == False %}
        {% do log('Executing DROP commands ...', True) %}
    {% else %}  
        {% do log('Printing DROP commands ...', True) %}
    {% endif %}

    {% for drop_command in drop_commands %}
        {% do log(drop_command, True) %}
        {% if dryrun | as_bool == False %}
            {% do run_query(drop_command) %}
        {% endif %}
    {% endfor %}
{% else %}
    {% do log('No relation to clean', True) %}
{% endif %}

{% endmacro %}